import { useState } from 'react';
import { api } from '../api.js';

const vacio = { sku: '', nombre: '', categoriaId: '', marcaId: '', precioCosto: '', precioVenta: '', stockMinimo: 0 };

export default function ProductoForm({ producto, categorias, marcas, onClose, onSaved }) {
  const editando = Boolean(producto);
  const [f, setF] = useState(
    editando
      ? {
          sku: producto.SKU, nombre: producto.Nombre,
          categoriaId: producto.CategoriaId, marcaId: producto.MarcaId,
          precioCosto: producto.PrecioCosto, precioVenta: producto.PrecioVenta,
          stockMinimo: producto.StockMinimo,
        }
      : vacio
  );
  const [errores, setErrores] = useState({});
  const [errorApi, setErrorApi] = useState('');
  const [guardando, setGuardando] = useState(false);

  const cambiar = (e) => setF({ ...f, [e.target.name]: e.target.value });

  // Validación en cliente (el backend y los CHECK de SQL validan de nuevo)
  const validar = () => {
    const er = {};
    if (!f.sku.trim()) er.sku = 'El SKU es obligatorio.';
    if (!f.nombre.trim()) er.nombre = 'El nombre es obligatorio.';
    if (!f.categoriaId) er.categoriaId = 'Seleccione una categoría.';
    if (!f.marcaId) er.marcaId = 'Seleccione una marca.';
    if (f.precioCosto === '' || Number(f.precioCosto) < 0) er.precioCosto = 'Debe ser un número >= 0.';
    if (f.precioVenta === '' || Number(f.precioVenta) < 0) er.precioVenta = 'Debe ser un número >= 0.';
    if (!Number.isInteger(Number(f.stockMinimo)) || Number(f.stockMinimo) < 0) er.stockMinimo = 'Debe ser un entero >= 0.';
    setErrores(er);
    return Object.keys(er).length === 0;
  };

  const enviar = async (e) => {
    e.preventDefault();
    setErrorApi('');
    if (!validar()) return;
    const body = {
      sku: f.sku.trim(), nombre: f.nombre.trim(),
      categoriaId: Number(f.categoriaId), marcaId: Number(f.marcaId),
      precioCosto: Number(f.precioCosto), precioVenta: Number(f.precioVenta),
      stockMinimo: Number(f.stockMinimo),
    };
    setGuardando(true);
    try {
      if (editando) await api.productos.actualizar(producto.ProductoId, body);
      else await api.productos.crear(body);
      onSaved();
    } catch (err) {
      setErrorApi(err.message); // ej. "Ya existe un producto con ese SKU."
    } finally {
      setGuardando(false);
    }
  };

  const Campo = ({ nombre, etiqueta, children }) => (
    <label className="campo">
      <span>{etiqueta}</span>
      {children}
      {errores[nombre] && <small className="error">{errores[nombre]}</small>}
    </label>
  );

  return (
    <div className="modal-fondo" onClick={onClose}>
      <form className="modal" onClick={(e) => e.stopPropagation()} onSubmit={enviar} noValidate>
        <h2>{editando ? 'Editar producto' : 'Nuevo producto'}</h2>
        {errorApi && <div className="alerta alerta-error">{errorApi}</div>}

        <div className="grid2">
          <Campo nombre="sku" etiqueta="SKU">
            <input name="sku" value={f.sku} onChange={cambiar} maxLength={30} />
          </Campo>
          <Campo nombre="nombre" etiqueta="Nombre">
            <input name="nombre" value={f.nombre} onChange={cambiar} maxLength={150} />
          </Campo>
          <Campo nombre="categoriaId" etiqueta="Categoría">
            <select name="categoriaId" value={f.categoriaId} onChange={cambiar}>
              <option value="">Seleccione…</option>
              {categorias.map((c) => <option key={c.CategoriaId} value={c.CategoriaId}>{c.Nombre}</option>)}
            </select>
          </Campo>
          <Campo nombre="marcaId" etiqueta="Marca">
            <select name="marcaId" value={f.marcaId} onChange={cambiar}>
              <option value="">Seleccione…</option>
              {marcas.map((m) => <option key={m.MarcaId} value={m.MarcaId}>{m.Nombre}</option>)}
            </select>
          </Campo>
          <Campo nombre="precioCosto" etiqueta="Precio costo">
            <input name="precioCosto" type="number" min="0" step="0.01" value={f.precioCosto} onChange={cambiar} />
          </Campo>
          <Campo nombre="precioVenta" etiqueta="Precio venta">
            <input name="precioVenta" type="number" min="0" step="0.01" value={f.precioVenta} onChange={cambiar} />
          </Campo>
          <Campo nombre="stockMinimo" etiqueta="Stock mínimo">
            <input name="stockMinimo" type="number" min="0" step="1" value={f.stockMinimo} onChange={cambiar} />
          </Campo>
        </div>

        <div className="acciones">
          <button type="button" className="btn" onClick={onClose}>Cancelar</button>
          <button type="submit" className="btn primario" disabled={guardando}>
            {guardando ? 'Guardando…' : 'Guardar'}
          </button>
        </div>
      </form>
    </div>
  );
}