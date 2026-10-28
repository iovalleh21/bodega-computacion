function errorHandler(error, req, res, next) {
  if (res.headersSent) {
    return next(error);
  }

  const isBusinessError =
    Number.isInteger(error.number) && error.number >= 50000 && error.number < 51000;

  if (isBusinessError) {
    return res.status(400).json({ error: error.message });
  }

  console.error(`${req.method} ${req.originalUrl}`, error);
  return res.status(error.statusCode || 500).json({
    error: error.statusCode ? error.message : 'Error interno del servidor',
  });
}

module.exports = errorHandler;
