const express = require('express');
const movimientos = require('../repositories/movimientos');
const { asyncHandler, requireBodyFields, requireInteger } = require('../middlewares/validate');

const router = express.Router();

function validateMovement(body) {
  requireBodyFields(body, ['idProducto', 'idUbicacion', 'cantidad']);
  return {
    ...body,
    idProducto: requireInteger(body.idProducto, 'idProducto', { positive: true }),
    idUbicacion: requireInteger(body.idUbicacion, 'idUbicacion', { positive: true }),
    cantidad: requireInteger(body.cantidad, 'cantidad', { positive: true }),
  };
}

router.post('/entrada', asyncHandler(async (req, res) => {
  res.status(201).json(await movimientos.registrarEntrada(validateMovement(req.body)));
}));

router.post('/salida', asyncHandler(async (req, res) => {
  res.status(201).json(await movimientos.registrarSalida(validateMovement(req.body)));
}));

router.get('/', asyncHandler(async (req, res) => {
  res.json(await movimientos.listar(req.query));
}));

module.exports = router;
