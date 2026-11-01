import { useEffect, useState, useCallback, useRef } from 'react';
import { api } from '../api.js';
import ProductoForm from './ProductoForm.jsx';

export default function Inventario() {
  const [productos, setProductos] = useState([]);
  const [categorias, setCategorias] = useState([]);
  const [marcas, setMarcas] = useState([]);
  const [q, setQ] = useState('');
  const [categoriaId, setCategoriaId] = useState('');
  const [error, setError] = useState('');
  const [cargando, setCargando] = useState(false);
  const [modal, setModal] = useState(null); // null | { producto: obj|null }

  // Catálogos una sola vez
  useEffect(() => {
    Promise.all([api.productos.categorias(), api.productos.marcas()])
      .then(([c, m]) => { setCategorias(c); setMarcas(m); })
      .catch((e) => setError(e.message));
  }, []);

  // Solo la última petición actualiza la pantalla (una respuesta lenta no pisa a una más reciente)
  const ultimaPeticion = useRef(0);

  const cargar = useCallback(async () => {
    const id = ++ultimaPeticion.current;
    setCargando(true);
    setError('');
    try {
      const datos = await api.productos.listar({ q: q.trim(), categoriaId });
      if (id === ultimaPeticion.current) setProductos(datos);
    } catch (e) {
      if (id === ultimaPeticion.current) setError(e.message);
    } finally {
      if (id === ultimaPeticion.current) setCargando(false);
    }
  }, [q, categoriaId]);

  // Búsqueda en tiempo real con debounce de 300 ms
  useEffect(() => {
    const t = setTimeout(cargar, 300);
    return () => clearTimeout(t);
  }, [cargar]);

  const desactivar = async (p) => {
    if (!window.confirm(`¿Desactivar "${p.Nombre}"? El historial se conserva.`)) return;
    try {
      await api.productos.desactivar(p.ProductoId);
      cargar();
    } catch (e) {
      setError(e.message);
    }
  };

  const totalBajo = productos.filter((p) => p.BajoStock).length;

  return (
    <section>
      <div className="toolbar">
        <input
          type="search"
          placeholder="Buscar por nombre o SKU…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
        <select value={categoriaId} onChange={(e) => setCategoriaId(e.target.value)}>
          <option value="">Todas las categorías</option>
          {categorias.map((c) => <option key={c.CategoriaId} value={c.CategoriaId}>{c.Nombre}</option>)}
        </select>
        <button className="btn primario" onClick={() => setModal({ producto: null })}>+ Nuevo producto</button>
      </div>

      {totalBajo > 0 && (
        <div className="alerta alerta-roja">⚠️ {totalBajo} producto(s) con stock igual o bajo el mínimo.</div>
      )}
      {error && <div className="alerta alerta-error">{error}</div>}

      <div className="tabla-wrap">
        <table>
          <thead>
            <tr>
              <th>SKU</th><th>Producto</th><th>Categoría</th><th>Marca</th>
              <th className="num">Stock</th><th className="num">Mínimo</th>
              <th className="num">Precio venta</th><th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {cargando && <tr><td colSpan="8" className="centro">Cargando…</td></tr>}
            {!cargando && productos.length === 0 && <tr><td colSpan="8" className="centro">Sin resultados</td></tr>}
            {!cargando && productos.map((p) => (
              // Fila en rojo cuando StockTotal <= StockMinimo (campo BajoStock desde la vista SQL)
              <tr key={p.ProductoId} className={p.BajoStock ? 'bajo-stock' : ''}>
                <td>{p.SKU}</td>
                <td>{p.Nombre}</td>
                <td>{p.Categoria}</td>
                <td>{p.Marca}</td>
                <td className="num"><strong>{p.StockTotal}</strong>{p.BajoStock && <span className="badge">BAJO</span>}</td>
                <td className="num">{p.StockMinimo}</td>
                <td className="num">${Number(p.PrecioVenta).toLocaleString('es-CL')}</td>
                <td>
                  <button className="btn" onClick={() => setModal({ producto: p })}>Editar</button>{' '}
                  <button className="btn peligro" onClick={() => desactivar(p)}>Desactivar</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {modal && (
        <ProductoForm
          producto={modal.producto}
          categorias={categorias}
          marcas={marcas}
          onClose={() => setModal(null)}
          onSaved={() => { setModal(null); cargar(); }}
        />
      )}
    </section>
  );
}