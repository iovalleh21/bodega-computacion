// Pruebas de la API con el servidor Express real. Todas fallan la validación ANTES de
// llegar a la base de datos, por lo que no necesitan SQL Server.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import app from '../src/app.js';

let server;
let base;

before(async () => {
  await new Promise((ok) => { server = app.listen(0, ok); });
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => server.close());

const get = (ruta) => fetch(base + ruta);
const enviar = (metodo, ruta, cuerpo) =>
  fetch(base + ruta, { method: metodo, headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(cuerpo) });

async function espera400(promesa, patron) {
  const r = await promesa;
  assert.equal(r.status, 400);
  const j = await r.json();
  if (patron) assert.match(j.error, patron);
}

test('GET /api/health responde ok', async () => {
  const r = await get('/api/health');
  assert.equal(r.status, 200);
  assert.deepEqual(await r.json(), { ok: true });
});

test('ruta inexistente => 404 en JSON', async () => {
  const r = await get('/api/no-existe');
  assert.equal(r.status, 404);
  assert.match((await r.json()).error, /no encontrada/i);
});

test('movimientos: cantidad 0, negativa o no entera => 400', async () => {
  const base = { productoId: 1, ubicacionId: 1 };
  await espera400(enviar('POST', '/api/movimientos/entrada', { ...base, cantidad: 0 }), /Cantidad/);
  await espera400(enviar('POST', '/api/movimientos/salida', { ...base, cantidad: -3 }), /Cantidad/);
  await espera400(enviar('POST', '/api/movimientos/salida', { ...base, cantidad: 1.5 }), /Cantidad/);
});

test('movimientos: faltan producto o ubicación => 400', async () => {
  await espera400(enviar('POST', '/api/movimientos/entrada', { cantidad: 1, ubicacionId: 1 }), /Producto/);
  await espera400(enviar('POST', '/api/movimientos/salida', { cantidad: 1, productoId: 1 }), /Ubicación/);
});

test('historial: fechas obligatorias, reales y tipo E/S => 400', async () => {
  await espera400(get('/api/movimientos'), /desde/);
  await espera400(get('/api/movimientos?desde=2026-13-45&hasta=2026-12-31'), /desde/);
  await espera400(get('/api/movimientos?desde=2026-01-01&hasta=ayer'), /hasta/);
  await espera400(get('/api/movimientos?desde=2026-01-01&hasta=2026-12-31&tipo=X'), /Tipo/);
});

test('productos: datos inválidos => 400', async () => {
  const valido = { sku: 'T-1', nombre: 'Prueba', categoriaId: 1, marcaId: 1, precioCosto: 10, precioVenta: 20 };
  await espera400(enviar('POST', '/api/productos', { ...valido, sku: '' }), /SKU/);
  await espera400(enviar('POST', '/api/productos', { ...valido, precioCosto: -1 }), /Precio costo/);
  await espera400(enviar('POST', '/api/productos', { ...valido, stockMinimo: -2 }), /Stock mínimo/);
  await espera400(enviar('PUT', '/api/productos/0', valido), /id/);
});

test('productos: identificadores y filtros mal formados => 400', async () => {
  await espera400(get('/api/productos/abc'), /id/);
  await espera400(get('/api/productos?categoriaId=abc'), /categoriaId/);
  await espera400(fetch(base + '/api/productos/xyz', { method: 'DELETE' }), /id/);
});

test('proveedores: RUT obligatorio => 400', async () => {
  await espera400(enviar('POST', '/api/proveedores', { nombre: 'Sin RUT' }), /RUT/);
  await espera400(enviar('PUT', '/api/proveedores/-1', { rut: '1-9', nombre: 'X' }), /id/);
});
