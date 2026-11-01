import { Router } from 'express';
import * as repo from '../repositories/reportes.js';
import { asyncHandler } from '../middleware/asyncHandler.js';

const router = Router();
router.get('/bajo-stock', asyncHandler(async (req, res) => res.json(await repo.bajoStock())));
router.get('/stock-por-categoria', asyncHandler(async (req, res) => res.json(await repo.stockPorCategoria())));
export default router;