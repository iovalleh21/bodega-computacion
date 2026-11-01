import { Router } from 'express';
import * as repo from '../repositories/proveedores.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { HttpError } from '../middleware/errorHandler.js';
import { entero, validarProveedor } from '../middleware/validar.js';

const router = Router();

router.get('/', asyncHandler(async (req, res) => res.json(await repo.listar())));

router.post('/', asyncHandler(async (req, res) => {
  const id = await repo.crear(validarProveedor(req.body));
  res.status(201).json({ proveedorId: id });
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const filas = await repo.actualizar(entero(req.params.id, 'id', { min: 1 }), validarProveedor(req.body));
  if (!filas) throw new HttpError(404, 'Proveedor no encontrado.');
  res.json({ ok: true });
}));

router.delete('/:id', asyncHandler(async (req, res) => {
  const filas = await repo.desactivar(entero(req.params.id, 'id', { min: 1 }));
  if (!filas) throw new HttpError(404, 'Proveedor no encontrado.');
  res.json({ ok: true });
}));

export default router;