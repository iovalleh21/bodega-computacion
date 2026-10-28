async function registrarEntrada() {
  throw new Error('El registro de entradas aún requiere el procedimiento almacenado de la base de datos');
}

async function registrarSalida() {
  throw new Error('El registro de salidas aún requiere el procedimiento almacenado de la base de datos');
}

async function listar() {
  throw new Error('La consulta de movimientos aún requiere el contrato de la base de datos');
}

module.exports = { registrarEntrada, registrarSalida, listar };
