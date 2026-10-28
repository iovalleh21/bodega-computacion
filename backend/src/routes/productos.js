const express = require('express');
const productos = require('../repositories/productos');
const { asyncHandler, requireInteger } = require('../middlewares/validate');

const router = express.Router();

router.get('/', asyncHandler(async (req, res) => {
  res.json(await productos.listar(req.query));
}));

router.post('/', asyncHandler(async (req, res) => {
  res.status(201).json(await productos.crear(req.body));
}));

router.put('/:id', asyncHandler(async (req, res) => {
  const id = requireInteger(req.params.id, 'id', { positive: true });
  res.json(await productos.actualizar(id, req.body));
}));

router.delete('/:id', asyncHandler(async (req, res) => {
  const id = requireInteger(req.params.id, 'id', { positive: true });
  res.json(await productos.desactivar(id));
}));

module.exports = router;
