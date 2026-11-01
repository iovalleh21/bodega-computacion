import { getPool } from '../db.js';

export async function bajoStock() {
  const r = await (await getPool()).request().query(`SELECT * FROM vw_ProductosBajoStock ORDER BY Faltante DESC`);
  return r.recordset;
}

export async function stockPorCategoria() {
  const r = await (await getPool()).request().query(`
    SELECT Categoria, COUNT(*) AS Productos, SUM(StockTotal) AS StockTotal
    FROM vw_StockProducto
    WHERE Activo = 1
    GROUP BY Categoria
    ORDER BY Categoria`);
  return r.recordset;
}