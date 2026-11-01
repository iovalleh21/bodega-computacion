// Las entradas/salidas se delegan a los SP transaccionales (rollback automático)
import { getPool, sql } from '../db.js';

export async function registrarEntrada({ productoId, ubicacionId, cantidad, proveedorId, referencia }) {
  const r = await (await getPool()).request()
    .input('ProductoId', sql.Int, productoId)
    .input('UbicacionId', sql.Int, ubicacionId)
    .input('Cantidad', sql.Int, cantidad)
    .input('ProveedorId', sql.Int, proveedorId)
    .input('Referencia', sql.NVarChar(200), referencia)
    .execute('sp_RegistrarEntrada');
  return r.recordset[0];
}

export async function registrarSalida({ productoId, ubicacionId, cantidad, referencia }) {
  const r = await (await getPool()).request()
    .input('ProductoId', sql.Int, productoId)
    .input('UbicacionId', sql.Int, ubicacionId)
    .input('Cantidad', sql.Int, cantidad)
    .input('Referencia', sql.NVarChar(200), referencia)
    .execute('sp_RegistrarSalida');
  return r.recordset[0];
}

export async function porRango({ desde, hasta, tipo }) {
  const r = await (await getPool()).request()
    .input('Desde', sql.VarChar(10), desde)   // 'AAAA-MM-DD' se convierte a DATE en el SP
    .input('Hasta', sql.VarChar(10), hasta)
    .input('Tipo', sql.Char(1), tipo)
    .execute('sp_MovimientosPorRango');
  return r.recordset;
}