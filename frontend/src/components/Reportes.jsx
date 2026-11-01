import { useEffect, useState } from 'react';
import { api } from '../api.js';

// Consume /api/reportes/*: vw_ProductosBajoStock y una agrupación (GROUP BY) de vw_StockProducto
export default function Reportes() {
  const [bajoStock, setBajoStock] = useState([]);
  const [porCategoria, setPorCategoria] = useState([]);
  const [error, setError] = useState('');
  const [cargando, setCargando] = useState(true);

  useEffect(() => {
    let vigente = true;
    Promise.all([api.reportes.bajoStock(), api.reportes.stockPorCategoria()])
      .then(([b, c]) => { if (vigente) { setBajoStock(b); setPorCategoria(c); } })
      .catch((e) => { if (vigente) setError(e.message); })
      .finally(() => { if (vigente) setCargando(false); });
    return () => { vigente = false; };
  }, []);

  const totalUnidades = porCategoria.reduce((suma, c) => suma + Number(c.StockTotal), 0);

  return (
    <section>
      {error && <div className="alerta alerta-error">{error}</div>}

      <h2>Productos con stock bajo</h2>
      <div className="tabla-wrap">
        <table>
          <thead>
            <tr>
              <th>SKU</th><th>Producto</th><th>Categoría</th><th>Marca</th>
              <th className="num">Stock</th><th className="num">Mínimo</th><th className="num">Faltante</th>
            </tr>
          </thead>
          <tbody>
            {cargando && <tr><td colSpan="7" className="centro">Cargando…</td></tr>}
            {!cargando && bajoStock.length === 0 && <tr><td colSpan="7" className="centro">Ningún producto bajo el mínimo</td></tr>}
            {!cargando && bajoStock.map((p) => (
              <tr key={p.ProductoId} className="bajo-stock">
                <td>{p.SKU}</td><td>{p.Nombre}</td><td>{p.Categoria}</td><td>{p.Marca}</td>
                <td className="num"><strong>{p.StockTotal}</strong></td>
                <td className="num">{p.StockMinimo}</td>
                <td className="num">{p.Faltante}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2>Stock por categoría</h2>
      <div className="tabla-wrap">
        <table>
          <thead>
            <tr><th>Categoría</th><th className="num">Productos</th><th className="num">Unidades en stock</th></tr>
          </thead>
          <tbody>
            {cargando && <tr><td colSpan="3" className="centro">Cargando…</td></tr>}
            {!cargando && porCategoria.length === 0 && <tr><td colSpan="3" className="centro">Sin datos</td></tr>}
            {!cargando && porCategoria.map((c) => (
              <tr key={c.Categoria}>
                <td>{c.Categoria}</td>
                <td className="num">{c.Productos}</td>
                <td className="num">{c.StockTotal}</td>
              </tr>
            ))}
          </tbody>
          {!cargando && porCategoria.length > 0 && (
            <tfoot>
              <tr><th>Total</th><th className="num">{porCategoria.reduce((s, c) => s + c.Productos, 0)}</th><th className="num">{totalUnidades}</th></tr>
            </tfoot>
          )}
        </table>
      </div>
    </section>
  );
}
