import { HttpError } from './errorHandler.js';

/** Convierte a entero >= min o lanza 400 */
export function entero(valor, nombre, { min = 0, requerido = true } = {}) {
  if (valor === undefined || valor === null || valor === '') {
    if (requerido) throw new HttpError(400, `${nombre} es obligatorio.`);
    return null;
  }
  const n = Number(valor);
  if (!Number.isInteger(n) || n < min) throw new HttpError(400, `${nombre} debe ser un entero >= ${min}.`);
  return n;
}

export function decimal(valor, nombre) {
  const n = Number(valor);
  if (valor === '' || valor === null || valor === undefined || !Number.isFinite(n) || n < 0)
    throw new HttpError(400, `${nombre} debe ser un número >= 0.`);
  return n;
}

export function texto(valor, nombre, { max = 150, requerido = true } = {}) {
  const t = (valor ?? '').toString().trim();
  if (!t) {
    if (requerido) throw new HttpError(400, `${nombre} es obligatorio.`);
    return null;
  }
  if (t.length > max) throw new HttpError(400, `${nombre} no puede superar ${max} caracteres.`);
  return t;
}

export function validarProducto(b = {}) {
  return {
    sku: texto(b.sku, 'SKU', { max: 30 }),
    nombre: texto(b.nombre, 'Nombre'),
    categoriaId: entero(b.categoriaId, 'Categoría', { min: 1 }),
    marcaId: entero(b.marcaId, 'Marca', { min: 1 }),
    precioCosto: decimal(b.precioCosto, 'Precio costo'),
    precioVenta: decimal(b.precioVenta, 'Precio venta'),
    stockMinimo: entero(b.stockMinimo ?? 0, 'Stock mínimo', { min: 0 }),
  };
}

export function validarProveedor(b = {}) {
  return {
    rut: texto(b.rut, 'RUT', { max: 12 }),
    nombre: texto(b.nombre, 'Nombre', { max: 120 }),
    email: texto(b.email, 'Email', { max: 120, requerido: false }),
    telefono: texto(b.telefono, 'Teléfono', { max: 30, requerido: false }),
  };
}

/** Exige AAAA-MM-DD y que sea una fecha real (rechaza 2026-13-45 o 2026-02-30). */
export function validarFechaISO(valor, nombre) {
  const msg = `${nombre} debe ser una fecha válida con formato AAAA-MM-DD.`;
  if (typeof valor !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(valor)) throw new HttpError(400, msg);
  const [a, m, d] = valor.split('-').map(Number);
  const f = new Date(Date.UTC(a, m - 1, d));
  const real = f.getUTCFullYear() === a && f.getUTCMonth() === m - 1 && f.getUTCDate() === d;
  // Rango acotado: el SP suma un día a "hasta" y DATETIME2 no tolera el límite superior
  if (!real || a < 1900 || a > 2100) throw new HttpError(400, msg);
  return valor;
}
