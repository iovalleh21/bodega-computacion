import { Router } from 'express';
import productos from './productos.js';
import proveedores from './proveedores.js';
import movimientos from './movimientos.js';
import reportes from './reportes.js';

const router = Router();
router.use('/productos', productos);
router.use('/proveedores', proveedores);
router.use('/movimientos', movimientos);
router.use('/reportes', reportes);
export default router;