import { getPool, sql } from '../db.js';

export async function listar() {
  const r = await (await getPool()).request()
    .query(`SELECT ProveedorId, Rut, Nombre, Email, Telefono FROM Proveedor WHERE Activo = 1 ORDER BY Nombre`);
  return r.recordset;
}

export async function crear(p) {
  const r = await (await getPool()).request()
    .input('rut', sql.NVarChar(12), p.rut)
    .input('nombre', sql.NVarChar(120), p.nombre)
    .input('email', sql.NVarChar(120), p.email)
    .input('telefono', sql.NVarChar(30), p.telefono)
    .query(`INSERT INTO Proveedor (Rut, Nombre, Email, Telefono)
            OUTPUT INSERTED.ProveedorId
            VALUES (@rut, @nombre, @email, @telefono)`);
  return r.recordset[0].ProveedorId;
}

export async function actualizar(id, p) {
  const r = await (await getPool()).request()
    .input('id', sql.Int, id)
    .input('rut', sql.NVarChar(12), p.rut)
    .input('nombre', sql.NVarChar(120), p.nombre)
    .input('email', sql.NVarChar(120), p.email)
    .input('telefono', sql.NVarChar(30), p.telefono)
    .query(`UPDATE Proveedor SET Rut = @rut, Nombre = @nombre, Email = @email, Telefono = @telefono
            WHERE ProveedorId = @id AND Activo = 1`);
  return r.rowsAffected[0];
}

export async function desactivar(id) {
  const r = await (await getPool()).request()
    .input('id', sql.Int, id)
    .query(`UPDATE Proveedor SET Activo = 0 WHERE ProveedorId = @id AND Activo = 1`);
  return r.rowsAffected[0];
}