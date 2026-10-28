const express = require('express');
const reportes = require('../repositories/reportes');
const { asyncHandler } = require('../middlewares/validate');

const router = express.Router();

router.get('/bajo-stock', asyncHandler(async (req, res) => {
  res.json(await reportes.bajoStock(req.query));
}));

router.get('/stock-categoria', asyncHandler(async (req, res) => {
  res.json(await reportes.stockPorCategoria(req.query));
}));

module.exports = router;
