// Pruebas unitarias de las validaciones (no necesitan SQL Server)
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { entero, decimal, texto, validarFechaISO, validarProducto, validarProveedor } from '../src/middleware/validar.js';
import { HttpError } from '../src/middleware/errorHandler.js';

const lanza400 = (fn) => assert.throws(fn, (e) => e instanceof HttpError && e.status === 400);

test('entero: acepta valores válidos y respeta el mínimo', () => {
  assert.equal(entero('5', 'Cantidad', { min: 1 }), 5);
  assert.equal(entero(0, 'Stock', { min: 0 }), 0);          // caso límite: el mínimo exacto
  lanza400(() => entero(0, 'Cantidad', { min: 1 }));         // por debajo del mínimo
  lanza400(() => entero(2.5, 'Cantidad', { min: 1 }));       // decimal
  lanza400(() => entero('abc', 'Cantidad', { min: 1 }));     // no numérico
  lanza400(() => entero(undefined, 'Cantidad', { min: 1 })); // obligatorio
});

test('entero: opcional devuelve null cuando falta', () => {
  assert.equal(entero(undefined, 'Proveedor', { min: 1, requerido: false }), null);
  assert.equal(entero('', 'Proveedor', { min: 1, requerido: false }), null);
});

test('decimal: rechaza negativos, vacíos, NaN e Infinity', () => {
  assert.equal(decimal('0', 'Precio'), 0);                  // caso límite
  assert.equal(decimal('1999.9', 'Precio'), 1999.9);
  lanza400(() => decimal(-1, 'Precio'));
  lanza400(() => decimal('', 'Precio'));
  lanza400(() => decimal('abc', 'Precio'));
  lanza400(() => decimal('Infinity', 'Precio'));
});

test('texto: recorta, exige y limita el largo', () => {
  assert.equal(texto('  hola  ', 'Nombre'), 'hola');
  assert.equal(texto('', 'Email', { requerido: false }), null);
  lanza400(() => texto('   ', 'Nombre'));
  lanza400(() => texto('x'.repeat(31), 'SKU', { max: 30 }));
});

test('validarFechaISO: solo fechas reales AAAA-MM-DD', () => {
  assert.equal(validarFechaISO('2026-02-28', 'desde'), '2026-02-28');
  assert.equal(validarFechaISO('2028-02-29', 'desde'), '2028-02-29'); // año bisiesto
  lanza400(() => validarFechaISO('2026-13-45', 'desde'));
  lanza400(() => validarFechaISO('2026-02-30', 'desde'));
  lanza400(() => validarFechaISO('2027-02-29', 'desde'));            // no bisiesto
  lanza400(() => validarFechaISO('01-11-2026', 'desde'));
  lanza400(() => validarFechaISO(undefined, 'desde'));
  lanza400(() => validarFechaISO('9999-12-31', 'hasta'));            // fuera del rango soportado
});

test('validarProducto: aplica valores por defecto y rechaza datos incompletos', () => {
  const ok = validarProducto({ sku: ' NB-1 ', nombre: 'Notebook', categoriaId: '1', marcaId: 2, precioCosto: '100', precioVenta: 150 });
  assert.deepEqual(ok, { sku: 'NB-1', nombre: 'Notebook', categoriaId: 1, marcaId: 2, precioCosto: 100, precioVenta: 150, stockMinimo: 0 });
  lanza400(() => validarProducto({}));
  lanza400(() => validarProducto({ sku: 'X', nombre: 'Y', categoriaId: 1, marcaId: 1, precioCosto: -5, precioVenta: 1 }));
});

test('validarProveedor: RUT y nombre obligatorios, el resto opcional', () => {
  assert.deepEqual(validarProveedor({ rut: '76.111.111-1', nombre: 'Tecno' }),
    { rut: '76.111.111-1', nombre: 'Tecno', email: null, telefono: null });
  lanza400(() => validarProveedor({ nombre: 'Sin RUT' }));
});
