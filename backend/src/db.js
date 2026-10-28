require('dotenv').config();

const sql = require('mssql');

const requiredEnvironment = ['DB_SERVER', 'DB_NAME', 'DB_USER', 'DB_PASSWORD'];
const missingEnvironment = requiredEnvironment.filter((name) => !process.env[name]);

if (missingEnvironment.length > 0) {
  throw new Error(`Faltan variables de entorno: ${missingEnvironment.join(', ')}`);
}

const config = {
  server: process.env.DB_SERVER,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  options: {
    trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE !== 'false',
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000,
  },
};

const poolPromise = new sql.ConnectionPool(config).connect();

poolPromise.catch((error) => {
  console.error('No se pudo conectar a SQL Server:', error.message);
});

module.exports = { sql, poolPromise };
