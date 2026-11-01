import 'dotenv/config';
import app from './app.js';
import { getPool } from './db.js';

const PORT = process.env.PORT || 3000;

// Verifica la conexión al iniciar, pero el servidor arranca igual (se reintenta por petición)
getPool()
  .then(() => console.log('[DB] Conectado a SQL Server'))
  .catch(() => console.warn('[DB] Sin conexión inicial; se reintentará.'));

app.listen(PORT, () => console.log(`API escuchando en http://localhost:${PORT}`));