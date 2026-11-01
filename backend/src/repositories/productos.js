// Acceso a datos de Producto: SQL explícito + .input() (sin concatenar entradas)
import { getPool, sql } from '../db.js';

export async function listar({ q = null, categoriaId = null } = {}) {
  const pool = await getPool();
  const r = await pool.request()
    .input('q', sql.NVarChar(100), q)
    .input('categoriaId', sql.Int, categoriaId)
    .query(`
      SELECT ProductoId, SKU, Nombre, CategoriaId, Categoria, MarcaId, Marca, 
             PrecioCosto, PrecioVenta, StockMinimo, StockTotal, BajoStock
      FROM vw_StockProducto
      WHERE Activo = 1
        AND (@q IS NULL OR Nombre LIKE '%' + @q + '%' OR SKU LIKE '%' + @q + '%')
        AND (@categoriaId IS NULL OR CategoriaId = @categoriaId)
      ORDER BY Nombre`);
  return r.recordset;
}

export async function obtener(id) {
  const pool = await getPool();
  const r = await pool.request()
    .input('id', sql.Int, id)
    .query(`SELECT * FROM vw_StockProducto WHERE ProductoId = @id AND Activo = 1`);
  return r.recordset[0] || null;
}

export async function crear(p) {
  const pool = await getPool();
  const r = await pool.request()
    .input('SKU', sql.NVarChar(30), p.sku)
    .input('Nombre', sql.NVarChar(150), p.nombre)
    .input('CategoriaId', sql.Int, p.categoriaId)
    .input('MarcaId', sql.Int, p.marcaId)
    .input('PrecioCosto', sql.Decimal(12, 2), p.precioCosto)
    .input('PrecioVenta', sql.Decimal(12, 2), p.precioVenta)
    .input('StockMinimo', sql.Int, p.stockMinimo)
    .execute('sp_CrearProducto');
  return r.recordset[0].ProductoId;
}

export async function actualizar(id, p) {
  const pool = await getPool();
  const r = await pool.request()
    .input('id', sql.Int, id)
    .input('sku', sql.NVarChar(30), p.sku)
    .input('nombre', sql.NVarChar(150), p.nombre)
    .input('categoriaId', sql.Int, p.categoriaId)
    .input('marcaId', sql.Int, p.marcaId)
    .input('precioCosto', sql.Decimal(12, 2), p.precioCosto)
    .input('precioVenta', sql.Decimal(12, 2), p.precioVenta)
    .input('stockMinimo', sql.Int, p.stockMinimo)
    .query(`
      UPDATE Producto
      SET SKU = @sku, Nombre = @nombre, CategoriaId = @categoriaId, MarcaId = @marcaId,
          PrecioCosto = @precioCosto, PrecioVenta = @precioVenta, StockMinimo = @stockMinimo
      WHERE ProductoId = @id AND Activo = 1`);
  return r.rowsAffected[0]; // 0 => no existe
}

// DELETE lógico (Activo = 0): se conserva el historial del Kardex
export async function desactivar(id) {
  const pool = await getPool();
  const r = await pool.request()
    .input('id', sql.Int, id)
    .query(`UPDATE Producto SET Activo = 0 WHERE ProductoId = @id AND Activo = 1`);
  return r.rowsAffected[0];
}

// Catálogos para los selects del frontend
export async function categorias() {
  const r = await (await getPool()).request().query(`SELECT CategoriaId, Nombre FROM Categoria ORDER BY Nombre`);
  return r.recordset;
}

export async function marcas() {
  const r = await (await getPool()).request().query(`SELECT MarcaId, Nombre FROM Marca ORDER BY Nombre`);
  return r.recordset;
}

export async function ubicaciones() {
  const r = await (await getPool()).request().query(`SELECT UbicacionId, Codigo, Descripcion FROM Ubicacion ORDER BY Codigo`);
  return r.recordset;
}