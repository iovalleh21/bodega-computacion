// Middleware central de errores.
// THROW 5xxxx de los SP -> 400 | duplicados/FK -> 409 | resto -> 500

export class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

// SQL Server nombra la restricción UNIQUE violada dentro del mensaje (error 2627/2601).
// Se usa para dar un mensaje preciso. Las filas desactivadas siguen ocupando su SKU/RUT.
const DUPLICADOS = [
  ['UQ_Producto_SKU', 'Ya existe un producto (activo o desactivado) con ese SKU.'],
  ['UQ_Proveedor_Rut', 'Ya existe un proveedor (activo o desactivado) con ese RUT.'],
  ['UQ_Categoria_Nombre', 'Ya existe una categoría con ese nombre.'],
  ['UQ_Marca_Nombre', 'Ya existe una marca con ese nombre.'],
  ['UQ_Ubicacion_Codigo', 'Ya existe una ubicación con ese código.'],
];

export function mensajeDuplicado(mensajeSql = '') {
  const hallado = DUPLICADOS.find(([restriccion]) => mensajeSql.includes(restriccion));
  return hallado ? hallado[1] : 'Registro duplicado.';
}

export function notFound(req, res) {
  res.status(404).json({ error: `Ruta no encontrada: ${req.method} ${req.originalUrl}` });
}

export function errorHandler(err, req, res, next) { // eslint-disable-line no-unused-vars
  // Errores propios (validación, 404, etc.)
  if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });

  // Número de error de SQL Server (mssql lo expone de dos formas)
  const num = err.number ?? err.originalError?.info?.number;

  if (num >= 50000 && num < 60000) {
    return res.status(400).json({ error: err.message, codigo: num });
  }
  if (num === 2627 || num === 2601) {
    return res.status(409).json({ error: mensajeDuplicado(err.message) });
  }
  if (num === 547) {
    return res.status(409).json({ error: 'Operación inválida: viola una restricción de la base de datos.' });
  }

  console.error('[ERROR]', err);
  res.status(500).json({ error: 'Error interno del servidor.' });
}