function requireInteger(value, fieldName, { positive = false } = {}) {
  const number = Number(value);

  if (!Number.isInteger(number) || (positive && number <= 0)) {
    const error = new Error(
      positive
        ? `${fieldName} debe ser un entero mayor que cero`
        : `${fieldName} debe ser un entero`,
    );
    error.statusCode = 400;
    throw error;
  }

  return number;
}

function requireBodyFields(body, fields) {
  const missingFields = fields.filter(
    (field) => body[field] === undefined || body[field] === null || body[field] === '',
  );

  if (missingFields.length > 0) {
    const error = new Error(`Faltan campos obligatorios: ${missingFields.join(', ')}`);
    error.statusCode = 400;
    throw error;
  }
}

function asyncHandler(handler) {
  return (req, res, next) => Promise.resolve(handler(req, res, next)).catch(next);
}

module.exports = { asyncHandler, requireBodyFields, requireInteger };
