const express = require('express');
const proveedores = require('../repositories/proveedores');
const { asyncHandler } = require('../middlewares/validate');

const router = express.Router();

router.get('/', asyncHandler(async (req, res) => {
  res.json(await proveedores.listar(req.query));
}));

router.post('/', asyncHandler(async (req, res) => {
  res.status(201).json(await proveedores.crear(req.body));
}));

module.exports = router;
