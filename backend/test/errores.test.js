// El manejador central traduce errores de SQL Server a respuestas HTTP coherentes
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { errorHandler, HttpError, mensajeDuplicado } from '../src/middleware/errorHandler.js';

function responder(err) {
  const res = { codigo: null, cuerpo: null, status(c) { this.codigo = c; return this; }, json(b) { this.cuerpo = b; return this; } };
  const consola = console.error;
  console.error = () => {};            // el 500 registra el error; se silencia en la prueba
  try { errorHandler(err, {}, res, () => {}); } finally { console.error = consola; }
  return res;
}

test('HttpError conserva su estado y mensaje', () => {
  const r = responder(new HttpError(404, 'Producto no encontrado.'));
  assert.equal(r.codigo, 404);
  assert.equal(r.cuerpo.error, 'Producto no encontrado.');
});

test('THROW 5xxxx de un procedimiento almacenado => 400 con el mensaje del SP', () => {
  const err = Object.assign(new Error('Stock insuficiente. Disponible: 5, solicitado: 10.'), { number: 50023 });
  const r = responder(err);
  assert.equal(r.codigo, 400);
  assert.equal(r.cuerpo.codigo, 50023);
  assert.match(r.cuerpo.error, /Stock insuficiente/);
});

test('el número de error también se lee desde originalError.info', () => {
  const err = Object.assign(new Error('x'), { originalError: { info: { number: 50011 } } });
  assert.equal(responder(err).codigo, 400);
});

test('UNIQUE violado => 409 con mensaje específico', () => {
  const err = Object.assign(new Error("Violation of UNIQUE KEY constraint 'UQ_Producto_SKU'."), { number: 2627 });
  const r = responder(err);
  assert.equal(r.codigo, 409);
  assert.match(r.cuerpo.error, /SKU/);
  assert.match(mensajeDuplicado("constraint 'UQ_Proveedor_Rut'"), /RUT/);
  assert.equal(mensajeDuplicado('otra restricción'), 'Registro duplicado.');
});

test('FOREIGN KEY violada => 409', () => {
  assert.equal(responder(Object.assign(new Error('fk'), { number: 547 })).codigo, 409);
});

test('error desconocido => 500 sin filtrar detalles internos', () => {
  const r = responder(new Error('password=secreto en la cadena de conexión'));
  assert.equal(r.codigo, 500);
  assert.doesNotMatch(r.cuerpo.error, /secreto/);
});
