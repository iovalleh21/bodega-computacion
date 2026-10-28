const express = require('express');
const cors = require('cors');

const errorHandler = require('./middlewares/errorHandler');
const movimientosRoutes = require('./routes/movimientos');
const productosRoutes = require('./routes/productos');
const proveedoresRoutes = require('./routes/proveedores');
const reportesRoutes = require('./routes/reportes');

const app = express();

app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.get('/api/health', (req, res) => {
  res.json({ ok: true, service: 'backend' });
});

app.use('/api/productos', productosRoutes);
app.use('/api/proveedores', proveedoresRoutes);
app.use('/api/movimientos', movimientosRoutes);
app.use('/api/reportes', reportesRoutes);

app.use((req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' });
});

app.use(errorHandler);

if (require.main === module) {
  const port = Number(process.env.PORT) || 3000;
  app.listen(port, () => {
    console.log(`Backend escuchando en http://localhost:${port}`);
  });
}

module.exports = app;
