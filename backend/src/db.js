// Pool de conexiones centralizado (singleton). Credenciales solo desde .env
import 'dotenv/config';
import sql from 'mssql/msnodesqlv8.js';

const server = process.env.DB_SERVER || '(local)';
const database = process.env.DB_NAME || 'BodegaComputadores';
const encrypt = process.env.DB_ENCRYPT === 'true' ? 'yes' : 'no';
const trustServerCertificate = process.env.DB_TRUST_CERT !== 'false'
  ? ';TrustServerCertificate=Yes'
  : '';
const trustedConnection = process.env.DB_TRUSTED !== 'false';
const connectionString = process.env.DB_CONNECTION_STRING
  || [
    `Driver={${process.env.DB_DRIVER || 'ODBC Driver 18 for SQL Server'}}`,
    `Server=${server}`,
    `Database=${database}`,
    trustedConnection
      ? 'Trusted_Connection=Yes'
      : `Uid=${process.env.DB_USER};Pwd=${process.env.DB_PASSWORD}`,
    `Encrypt=${encrypt}${trustServerCertificate}`,
  ].join(';');

const config = {
  connectionString,
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