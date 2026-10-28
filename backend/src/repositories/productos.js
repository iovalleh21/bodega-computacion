async function listar() {
  throw new Error('La consulta de productos aún requiere el contrato de la base de datos');
}

async function crear() {
  throw new Error('La creación de productos aún requiere el procedimiento almacenado de la base de datos');
}

async function actualizar() {
  throw new Error('La actualización de productos aún requiere el contrato de la base de datos');
}

async function desactivar() {
  throw new Error('La desactivación de productos aún requiere el contrato de la base de datos');
}

module.exports = { listar, crear, actualizar, desactivar };
