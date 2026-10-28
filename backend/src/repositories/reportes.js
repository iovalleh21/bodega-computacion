async function bajoStock() {
  throw new Error('El reporte de bajo stock aún requiere el contrato de la base de datos');
}

async function stockPorCategoria() {
  throw new Error('El reporte por categoría aún requiere el contrato de la base de datos');
}

module.exports = { bajoStock, stockPorCategoria };
