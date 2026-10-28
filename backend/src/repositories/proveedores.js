async function listar() {
  throw new Error('La consulta de proveedores aún requiere el contrato de la base de datos');
}

async function crear() {
  throw new Error('La creación de proveedores aún requiere el contrato de la base de datos');
}

module.exports = { listar, crear };
