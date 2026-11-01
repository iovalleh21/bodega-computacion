import { useEffect, useState, useCallback } from 'react';
import { api } from '../api.js';

const hoy = () => new Date().toISOString().slice(0, 10);
const haceUnMes = () => new Date(Date.now() - 30 * 864e5).toISOString().slice(0, 10);

export default function Movimientos() {
  // Catálogos
  const [productos, setProductos] = useState([]);
  const [ubicaciones, setUbicaciones] = useState([]);
  const [proveedores, setProveedores] = useState([]);

  // Formulario
  const [tipo, setTipo] = useState('E');
  const [form, setForm] = useState({ productoId: '', ubicacionId: '', cantidad: '', proveedorId: '', referencia: '' });
  const [msg, setMsg] = useState(null); // { tipo: 'ok'|'error', texto }
  const [enviando, setEnviando] = useState(false);

  // Historial
  const [filtros, setFiltros] = useState({ desde: haceUnMes(), hasta: hoy(), tipo: '' });
  const [historial, setHistorial] = useState([]);
  const [errorHist, setErrorHist] = useState('');

  const cargarCatalogos = useCallback(async () => {
    try {
      const [p, u, pr] = await Promise.all([
        api.productos.listar({}), api.productos.ubicaciones(), api.proveedores.listar(),
      ]);
      setProductos(p); setUbicaciones(u); setProveedores(pr);
    } catch (e) {
      setMsg({ tipo: 'error', texto: e.message });
    }
  }, []);

  const cargarHistorial = useCallback(async () => {
    setErrorHist('');
    try {
      setHistorial(await api.movimientos.listar(filtros));
    } catch (e) {
      setHistorial([]);
      setErrorHist(e.message); // ej. rango de fechas invertido (error del SP, HTTP 400)
    }
  }, [filtros]);

  useEffect(() => { cargarCatalogos(); }, [cargarCatalogos]);
  useEffect(() => { cargarHistorial(); }, [cargarHistorial]);

  const cambiar = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const enviar = async (e) => {
    e.preventDefault();
    setMsg(null);
    if (!form.productoId || !form.ubicacionId) return setMsg({ tipo: 'error', texto: 'Seleccione producto y ubicación.' });
    if (!Number.isInteger(Number(form.cantidad)) || Number(form.cantidad) < 1)
      return setMsg({ tipo: 'error', texto: 'La cantidad debe ser un entero mayor a 0.' });

    const body = {
      productoId: Number(form.productoId),
      ubicacionId: Number(form.ubicacionId),
      cantidad: Number(form.cantidad),
      referencia: form.referencia.trim() || undefined,
    };
    if (tipo === 'E' && form.proveedorId) body.proveedorId = Number(form.proveedorId);

    setEnviando(true);
    try {
      const r = tipo === 'E' ? await api.movimientos.entrada(body) : await api.movimientos.salida(body);
      setMsg({ tipo: 'ok', texto: `Movimiento #${r.MovimientoId} registrado. Stock total del producto: ${r.StockTotal}.` });
      setForm({ ...form, cantidad: '', referencia: '' });
      cargarCatalogos();   // refresca stock mostrado en el select
      cargarHistorial();
    } catch (err) {
      // Muestra el error real de la API, p. ej. "Stock insuficiente. Disponible: 5, solicitado: 10."
      setMsg({ tipo: 'error', texto: err.message });
    } finally {
      setEnviando(false);
    }
  };

  return (
    <section>
      <h2>Registrar movimiento</h2>
      <form className="card" onSubmit={enviar} noValidate>
        <div className="segmentado">
          <button type="button" className={tipo === 'E' ? 'seg activo entrada' : 'seg'} onClick={() => setTipo('E')}>⬇ Entrada</button>
          <button type="button" className={tipo === 'S' ? 'seg activo salida' : 'seg'} onClick={() => setTipo('S')}>⬆ Salida</button>
        </div>

        <div className="grid2">
          <label className="campo"><span>Producto</span>
            <select name="productoId" value={form.productoId} onChange={cambiar}>
              <option value="">Seleccione…</option>
              {productos.map((p) => (
                <option key={p.ProductoId} value={p.ProductoId}>{p.SKU} — {p.Nombre} (stock {p.StockTotal})</option>
              ))}
            </select>
          </label>
          <label className="campo"><span>Ubicación</span>
            <select name="ubicacionId" value={form.ubicacionId} onChange={cambiar}>
              <option value="">Seleccione…</option>
              {ubicaciones.map((u) => <option key={u.UbicacionId} value={u.UbicacionId}>{u.Codigo} — {u.Descripcion}</option>)}
            </select>
          </label>
          <label className="campo"><span>Cantidad</span>
            <input name="cantidad" type="number" min="1" step="1" value={form.cantidad} onChange={cambiar} />
          </label>
          {tipo === 'E' && (
            <label className="campo"><span>Proveedor (opcional)</span>
              <select name="proveedorId" value={form.proveedorId} onChange={cambiar}>
                <option value="">— Sin proveedor —</option>
                {proveedores.map((p) => <option key={p.ProveedorId} value={p.ProveedorId}>{p.Nombre}</option>)}
              </select>
            </label>
          )}
          <label className="campo ancho"><span>Referencia</span>
            <input name="referencia" value={form.referencia} onChange={cambiar} maxLength={200} placeholder="N° de factura, guía, motivo…" />
          </label>
        </div>

        {msg && <div className={msg.tipo === 'ok' ? 'alerta alerta-ok' : 'alerta alerta-error'}>{msg.texto}</div>}

        <button type="submit" className="btn primario" disabled={enviando}>
          {enviando ? 'Registrando…' : `Registrar ${tipo === 'E' ? 'entrada' : 'salida'}`}
        </button>
      </form>

      <h2>Historial (Kardex)</h2>
      <div className="toolbar">
        <label>Desde <input type="date" value={filtros.desde} onChange={(e) => setFiltros({ ...filtros, desde: e.target.value })} /></label>
        <label>Hasta <input type="date" value={filtros.hasta} onChange={(e) => setFiltros({ ...filtros, hasta: e.target.value })} /></label>
        <select value={filtros.tipo} onChange={(e) => setFiltros({ ...filtros, tipo: e.target.value })}>
          <option value="">Entradas y salidas</option>
          <option value="E">Solo entradas</option>
          <option value="S">Solo salidas</option>
        </select>
      </div>
      {errorHist && <div className="alerta alerta-error">{errorHist}</div>}

      <div className="tabla-wrap">
        <table>
          <thead>
            <tr><th>#</th><th>Fecha</th><th>Tipo</th><th>SKU</th><th>Producto</th><th>Ubicación</th><th>Proveedor</th><th className="num">Cant.</th><th>Referencia</th></tr>
          </thead>
          <tbody>
            {historial.length === 0 && <tr><td colSpan="9" className="centro">Sin movimientos en el rango</td></tr>}
            {historial.map((m) => (
              <tr key={m.MovimientoId}>
                <td>{m.MovimientoId}</td>
                <td>{new Date(m.Fecha).toLocaleString('es-CL')}</td>
                <td><span className={m.Tipo === 'E' ? 'pill entrada' : 'pill salida'}>{m.TipoDescripcion}</span></td>
                <td>{m.SKU}</td><td>{m.Producto}</td><td>{m.Ubicacion}</td>
                <td>{m.Proveedor || '—'}</td>
                <td className="num">{m.Cantidad}</td>
                <td>{m.Referencia || '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}