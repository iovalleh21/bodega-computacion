import { useEffect, useState } from 'react';
import { api } from '../api.js';

const vacio = { rut: '', nombre: '', email: '', telefono: '' };

// Formato chileno: 12.345.678-9 o 12345678-K (los puntos son opcionales)
const RUT_REGEX = /^\d{1,2}\.?\d{3}\.?\d{3}-[\dkK]$/;
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function Proveedores() {
  const [proveedores, setProveedores] = useState([]);
  const [filtro, setFiltro] = useState('');
  const [form, setForm] = useState(vacio);
  const [errores, setErrores] = useState({});
  const [msg, setMsg] = useState(null);        // { tipo: 'ok' | 'error', texto }
  const [cargando, setCargando] = useState(true);
  const [guardando, setGuardando] = useState(false);
  const [recarga, setRecarga] = useState(0);  // se incrementa para volver a consultar la API

  useEffect(() => {
    let vigente = true;
    api.proveedores.listar()
      .then((datos) => { if (vigente) setProveedores(datos); })
      .catch((e) => { if (vigente) setMsg({ tipo: 'error', texto: e.message }); })
      .finally(() => { if (vigente) setCargando(false); });
    return () => { vigente = false; };
  }, [recarga]);

  const cambiar = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  // Validación en cliente (el backend y los UNIQUE/CHECK de SQL validan de nuevo)
  const validar = () => {
    const er = {};
    if (!RUT_REGEX.test(form.rut.trim())) er.rut = 'RUT inválido. Ej: 76.123.456-7';
    if (!form.nombre.trim()) er.nombre = 'El nombre es obligatorio.';
    if (form.email.trim() && !EMAIL_REGEX.test(form.email.trim())) er.email = 'Email inválido.';
    setErrores(er);
    return Object.keys(er).length === 0;
  };

  const enviar = async (e) => {
    e.preventDefault();
    setMsg(null);
    if (!validar()) return;

    setGuardando(true);
    try {
      await api.proveedores.crear({
        rut: form.rut.trim(),
        nombre: form.nombre.trim(),
        email: form.email.trim() || undefined,
        telefono: form.telefono.trim() || undefined,
      });
      setMsg({ tipo: 'ok', texto: 'Proveedor registrado correctamente.' });
      setForm(vacio);
      setErrores({});
      setRecarga((n) => n + 1);
    } catch (err) {
      // Ej: 409 "Ya existe un proveedor (activo o desactivado) con ese RUT."
      setMsg({ tipo: 'error', texto: err.message });
    } finally {
      setGuardando(false);
    }
  };

  const desactivar = async (p) => {
    if (!window.confirm(`¿Desactivar al proveedor "${p.Nombre}"?`)) return;
    try {
      await api.proveedores.desactivar(p.ProveedorId);
      setRecarga((n) => n + 1);
    } catch (err) {
      setMsg({ tipo: 'error', texto: err.message });
    }
  };

  // Filtro en cliente sobre la lista ya cargada
  const visibles = proveedores.filter((p) => {
    const t = filtro.trim().toLowerCase();
    return !t || p.Nombre.toLowerCase().includes(t) || p.Rut.toLowerCase().includes(t);
  });

  return (
    <section className="layout-prov">
      {/* ---------- Formulario de alta ---------- */}
      <form className="card" onSubmit={enviar} noValidate>
        <h2 style={{ marginTop: 0 }}>Nuevo proveedor</h2>

        <label className="campo">
          <span>RUT</span>
          <input name="rut" value={form.rut} onChange={cambiar} maxLength={12} placeholder="76.123.456-7" />
          {errores.rut && <small className="error">{errores.rut}</small>}
        </label>
        <label className="campo">
          <span>Nombre / Razón social</span>
          <input name="nombre" value={form.nombre} onChange={cambiar} maxLength={120} />
          {errores.nombre && <small className="error">{errores.nombre}</small>}
        </label>
        <label className="campo">
          <span>Email (opcional)</span>
          <input name="email" type="email" value={form.email} onChange={cambiar} maxLength={120} />
          {errores.email && <small className="error">{errores.email}</small>}
        </label>
        <label className="campo">
          <span>Teléfono (opcional)</span>
          <input name="telefono" value={form.telefono} onChange={cambiar} maxLength={30} />
        </label>

        {msg && <div className={msg.tipo === 'ok' ? 'alerta alerta-ok' : 'alerta alerta-error'}>{msg.texto}</div>}

        <button type="submit" className="btn primario" disabled={guardando}>
          {guardando ? 'Guardando…' : 'Registrar proveedor'}
        </button>
      </form>

      {/* ---------- Listado ---------- */}
      <div>
        <div className="toolbar">
          <input type="search" placeholder="Filtrar por nombre o RUT…" value={filtro} onChange={(e) => setFiltro(e.target.value)} />
        </div>
        <div className="tabla-wrap">
          <table>
            <thead>
              <tr><th>RUT</th><th>Nombre</th><th>Email</th><th>Teléfono</th><th>Acciones</th></tr>
            </thead>
            <tbody>
              {cargando && <tr><td colSpan="5" className="centro">Cargando…</td></tr>}
              {!cargando && visibles.length === 0 && <tr><td colSpan="5" className="centro">Sin proveedores</td></tr>}
              {!cargando && visibles.map((p) => (
                <tr key={p.ProveedorId}>
                  <td>{p.Rut}</td>
                  <td>{p.Nombre}</td>
                  <td>{p.Email || '—'}</td>
                  <td>{p.Telefono || '—'}</td>
                  <td><button className="btn peligro" onClick={() => desactivar(p)}>Desactivar</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  );
}