import { Router } from 'express';
import * as repo from '../repositories/productos.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { HttpError } from '../middleware/errorHandler.js';
import { entero, validarProducto } from '../middleware/validar.js';

const router = Router();

// GET /api/productos?q=texto&categoriaId=1
router.get('/', asyncHandler(async (req, res) => {
  const q = req.query.q ? String(req.query.q).trim().slice(0, 100) : null;
  const categoriaId = req.query.categoriaId ? entero(req.query.categoriaId, 'categoriaId', { min: 1 }) : null;
  res.json(await repo.listar({ q, categoriaId }));
}));

// Catálogos (antes de '/:id' para que no choquen)
router.get('/catalogos/categorias',   asyncHandler(async (req, res) => res.json(await repo.categorias())));
router.get('/catalogos/marcas',       asyncHandler(async (req, res) => res.json(await repo.marcas())));
router.get('/catalogos/ubicaciones',  asyncHandler(async (req, res) => res.json(await repo.ubicaciones())));

router.get('/:id', asyncHandler(async (req, res) => {
  const p = await repo.obtener(entero(req.params.id, 'id', { min: 1 }));
  if (!p) throw new HttpError(404, 'Producto no encontrado.');
  res.json(p);
}));

router.post('/', asyncHandler(async (req, res) => {
  const id = await repo.crear(validarProducto(req.body));
  res.status(201).json({ productoId: id });
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const id = entero(req.params.id, 'id', { min: 1 });
  const filas = await repo.actualizar(id, validarProducto(req.body));
  if (!filas) throw new HttpError(404, 'Producto no encontrado.');
  res.json({ ok: true });
}));

router.delete('/:id', asyncHandler(async (req, res) => {
  const filas = await repo.desactivar(entero(req.params.id, 'id', { min: 1 }));
  if (!filas) throw new HttpError(404, 'Producto no encontrado.');
  res.json({ ok: true });
}));

export default router;