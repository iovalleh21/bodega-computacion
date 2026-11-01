import { Router } from 'express';
import * as repo from '../repositories/movimientos.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { HttpError } from '../middleware/errorHandler.js';
import { entero, texto, validarFechaISO } from '../middleware/validar.js';

const router = Router();

// POST /api/movimientos/entrada
router.post('/entrada', asyncHandler(async (req, res) => {
  const b = req.body || {};
  const r = await repo.registrarEntrada({
    productoId: entero(b.productoId, 'Producto', { min: 1 }),
    ubicacionId: entero(b.ubicacionId, 'Ubicación', { min: 1 }),
    cantidad: entero(b.cantidad, 'Cantidad', { min: 1 }),
    proveedorId: entero(b.proveedorId, 'Proveedor', { min: 1, requerido: false }),
    referencia: texto(b.referencia, 'Referencia', { max: 200, requerido: false }),
  });
  res.status(201).json(r);
}));

// POST /api/movimientos/salida  (stock insuficiente => SP lanza 50023 => 400)
router.post('/salida', asyncHandler(async (req, res) => {
  const b = req.body || {};
  const r = await repo.registrarSalida({
    productoId: entero(b.productoId, 'Producto', { min: 1 }),
    ubicacionId: entero(b.ubicacionId, 'Ubicación', { min: 1 }),
    cantidad: entero(b.cantidad, 'Cantidad', { min: 1 }),
    referencia: texto(b.referencia, 'Referencia', { max: 200, requerido: false }),
  });
  res.status(201).json(r);
}));

// GET /api/movimientos?desde=2026-01-01&hasta=2026-12-31&tipo=E
router.get('/', asyncHandler(async (req, res) => {
  const { desde, hasta, tipo } = req.query;
  if (tipo && !['E', 'S'].includes(tipo)) throw new HttpError(400, 'Tipo debe ser E o S.');
  res.json(await repo.porRango({
    desde: validarFechaISO(desde, 'desde'),
    hasta: validarFechaISO(hasta, 'hasta'),   // el orden de fechas lo valida el SP (50031)
    tipo: tipo || null,
  }));
}));

export default router;