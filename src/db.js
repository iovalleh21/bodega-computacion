// Pool de conexiones centralizado (singleton). Credenciales solo desde .env
import 'dotenv/config';
import sql from 'mssql';

const config = {
  server: process.env.DB_SERVER,
  port: Number(process.env.DB_PORT || 1433),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  options: {
    encrypt: process.env.DB_ENCRYPT === 'true',
    trustServerCertificate: process.env.DB_TRUST_CERT !== 'false',
  },
  pool: { max: 10, min: 0, idleTimeoutMillis: 30000 },
};

let poolPromise = null;

/** Devuelve siempre el mismo pool; si la conexión falla, permite reintentar. */
export function getPool() {
  if (!poolPromise) {
    const pool = new sql.ConnectionPool(config);
    pool.on('error', (err) => console.error('[DB] Error en el pool:', err.message));
    poolPromise = pool.connect().catch((err) => {
      poolPromise = null; // permite reintentar en la siguiente petición
      console.error('[DB] No se pudo conectar a SQL Server:', err.message);
      throw err;
    });
  }
  return poolPromise;
}

export { sql };