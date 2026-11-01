# Documentación – Bodega de Computadores (avance 60 %)

## 1. Arquitectura

| Capa | Tecnología | Responsabilidad |
|---|---|---|
| Frontend (`frontend/`) | React 19 + Vite | Interacción con el usuario, validación en cliente, llamadas a la API (`src/api.js`) |
| Backend (`backend/`) | Node.js + Express | API REST, validación, mapeo de errores, ejecución de SQL |
| Base de datos (`database/`) | SQL Server | Tablas, restricciones, vistas y procedimientos almacenados |

Reglas de la arquitectura:

- El frontend **no** se conecta a SQL Server: solo usa `fetch` contra `/api`. En desarrollo Vite
  redirige `/api` a `http://localhost:3000`; en otro entorno se define `VITE_API_URL`.
- El backend es el único que accede a la base, a través de `backend/src/db.js` (pool de `mssql`
  sobre `msnodesqlv8`, con ODBC Driver 18 en Windows). Las credenciales viven solo en
  `backend/.env`, que no se sube al repositorio.
- **No se usa ORM**: todo el SQL está escrito en `backend/src/repositories/*.js` o en los
  procedimientos de `database/01_base_datos.sql`, y se ejecuta con parámetros (`.input()`), sin
  concatenar datos del usuario.

Capas internas del backend: `routes/` (HTTP y validación de entrada) → `middleware/validar.js`
(reglas de validación) → `repositories/` (SQL) → `db.js` (conexión). Los errores se centralizan en
`middleware/errorHandler.js`.

## 2. Modelo de datos

```
Categoria 1──* Producto *──1 Marca
                  │ 1
                  ├──* Stock *──1 Ubicacion        (PK compuesta: ProductoId + UbicacionId)
                  └──* Movimiento *──1 Ubicacion
                            *──0..1 Proveedor
```

| Tabla | Descripción | Restricciones relevantes |
|---|---|---|
| `Categoria`, `Marca` | Catálogos | `UNIQUE(Nombre)` |
| `Producto` | Artículo del inventario | `UNIQUE(SKU)`, `PrecioCosto >= 0`, `PrecioVenta >= 0`, `StockMinimo >= 0`, FK a Categoría y Marca, `Activo` (borrado lógico) |
| `Ubicacion` | Pasillo/estante | `UNIQUE(Codigo)` |
| `Stock` | Cantidad por producto y ubicación | PK compuesta, `Cantidad >= 0` |
| `Proveedor` | Proveedores | `UNIQUE(Rut)`, `Activo` |
| `Movimiento` | Kardex (entradas `E` y salidas `S`) | `Cantidad > 0`, `Tipo IN ('E','S')`, FK a Producto, Ubicación y Proveedor (opcional), índices por fecha y producto |

Decisiones de diseño:

- **Borrado lógico** (`Activo = 0`): el historial del Kardex se conserva. Por eso el SKU o RUT de un
  registro desactivado sigue ocupado, y la API lo indica en el mensaje de error.
- `Stock` guarda el saldo actual por ubicación y `Movimiento` el historial; los procedimientos
  mantienen ambos consistentes dentro de una transacción.

## 3. Objetos SQL y dónde se usan

| Objeto | Qué resuelve | Lo consume |
|---|---|---|
| `vw_StockProducto` | Producto + categoría + marca + stock total (`JOIN`, `LEFT JOIN`, `SUM`, `GROUP BY`) y la marca `BajoStock` | `GET /productos`, `GET /productos/:id`, `GET /reportes/stock-por-categoria` → Inventario, Movimientos, Reportes |
| `vw_ProductosBajoStock` | Productos activos en o bajo su mínimo, con el faltante | `GET /reportes/bajo-stock` → pestaña Reportes |
| `vw_MovimientosDetalle` | Kardex con producto, ubicación y proveedor ya unidos | `sp_MovimientosPorRango` |
| `sp_CrearProducto` | Alta de producto con validaciones y transacción | `POST /productos` |
| `sp_RegistrarEntrada` | Suma stock (crea o actualiza la fila de `Stock`) y registra el movimiento, en una transacción con bloqueo | `POST /movimientos/entrada` |
| `sp_RegistrarSalida` | Descuenta stock verificando que alcance y registra el movimiento, en una transacción con bloqueo | `POST /movimientos/salida` |
| `sp_MovimientosPorRango` | Kardex filtrado por fechas y tipo | `GET /movimientos` |

El resto del acceso a datos (listar/editar/desactivar productos, catálogos y proveedores) usa
consultas explícitas y parametrizadas; todo `UPDATE` incluye `WHERE <id> AND Activo = 1`, por lo que no
puede modificar filas de más.

Regla de "bajo stock": `StockMinimo > 0 AND StockTotal <= StockMinimo`. Un producto con mínimo 0 no
tiene umbral de reposición y no se marca (antes todo producto nuevo aparecía como bajo stock).

### Códigos de error de los procedimientos

El backend los traduce a HTTP 400 con el mensaje del procedimiento.

| Procedimiento | Códigos |
|---|---|
| `sp_CrearProducto` | 50001 datos obligatorios · 50002 valores negativos · 50003 SKU duplicado · 50004 categoría o marca inexistente |
| `sp_RegistrarEntrada` | 50010 cantidad inválida · 50011 producto · 50012 ubicación · 50013 proveedor |
| `sp_RegistrarSalida` | 50020 cantidad inválida · 50021 producto · 50022 ubicación · 50023 stock insuficiente |
| `sp_MovimientosPorRango` | 50030 faltan fechas · 50031 rango invertido · 50032 tipo inválido |

Violaciones de `UNIQUE` (2627/2601) y `FOREIGN KEY` (547) responden 409; cualquier otro error, 500 sin
detalles internos.

## 4. API

| Método y ruta | Descripción |
|---|---|
| `GET /api/health` | Estado del servicio |
| `GET /api/productos?q=&categoriaId=` | Lista productos activos con su stock |
| `GET/POST/PUT/DELETE /api/productos[/:id]` | Detalle, alta, edición y desactivación |
| `GET /api/productos/catalogos/{categorias,marcas,ubicaciones}` | Catálogos para los selectores |
| `GET/POST/PUT/DELETE /api/proveedores[/:id]` | Proveedores |
| `POST /api/movimientos/entrada` · `POST /api/movimientos/salida` | Registrar movimiento |
| `GET /api/movimientos?desde=AAAA-MM-DD&hasta=AAAA-MM-DD&tipo=E\|S` | Historial (Kardex) |
| `GET /api/reportes/bajo-stock` · `GET /api/reportes/stock-por-categoria` | Reportes |

## 5. Pruebas y evidencia

| Qué | Dónde | Cómo se ejecuta |
|---|---|---|
| Procedimientos y vistas: casos normales, límite y de error, con el resultado esperado impreso como `OK`/`FALLO` | `database/02_pruebas.sql` | Ejecutar en SSMS después de crear la base. Crea dos productos `TEST-001/002` y los elimina al final |
| Validaciones, manejo de errores y rutas de la API (21 pruebas) | `backend/test/*.test.js` | `cd backend && npm test` (no requiere SQL Server) |
| Lint y compilación del frontend | `frontend/` | `npm run lint` · `npm run build` |

Casos que cubre `02_pruebas.sql`: alta con y sin umbral de reposición; SKU duplicado, precio negativo,
SKU vacío y categoría inexistente; entrada en dos ubicaciones; cantidad 0, producto, ubicación y
proveedor inexistentes; salida que deja el stock exactamente en el mínimo y en cero; salida con stock
insuficiente (verificando que el *rollback* no deja movimientos ni cambia el stock); historial de un
solo día, por tipo, sin resultados, con rango invertido, tipo inválido y fechas nulas.

## 6. Propuesta para la entrega final

### Trigger: auditoría de cambios en `Producto`

**Necesidad.** `PUT /productos/:id` y `DELETE /productos/:id` modifican `Producto` con un `UPDATE`
directo, y hoy no queda registro de quién cambió un precio, el stock mínimo o la desactivación. Es una
necesidad transversal: la auditoría debe ocurrir sin importar si el cambio viene de la API, de un
procedimiento o de alguien que ejecute SQL a mano, por eso se justifica un trigger y no código en el
backend.

**Diseño.** Tabla `AuditoriaProducto(AuditoriaId, ProductoId, Campo, ValorAnterior, ValorNuevo, Fecha,
Usuario)` y un `AFTER UPDATE` sobre `Producto` que compara `inserted` con `deleted` y registra una
fila por cada campo que cambió (`PrecioCosto`, `PrecioVenta`, `StockMinimo`, `Activo`). Se escribe
orientado a conjuntos, de modo que un `UPDATE` de varias filas queda correctamente auditado:

```sql
CREATE TRIGGER trg_Producto_Auditoria ON dbo.Producto AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.AuditoriaProducto (ProductoId, Campo, ValorAnterior, ValorNuevo)
    SELECT i.ProductoId, N'PrecioVenta', CONVERT(NVARCHAR(100), d.PrecioVenta), CONVERT(NVARCHAR(100), i.PrecioVenta)
    FROM inserted i JOIN deleted d ON d.ProductoId = i.ProductoId
    WHERE i.PrecioVenta <> d.PrecioVenta;
    -- idem para PrecioCosto, StockMinimo y Activo
END;
```

Se integra con un `GET /api/productos/:id/historial` y una vista en el frontend.

### Cursor: importación masiva de movimientos

**Necesidad.** Cargar una guía de despacho o recepción con muchas líneas (tabla `MovimientoImportacion`
con producto, ubicación, tipo y cantidad). Cada línea debe pasar por `sp_RegistrarEntrada` o
`sp_RegistrarSalida` para respetar sus validaciones, y **cada una debe tener su propia transacción**:
si la línea 7 falla por stock insuficiente, las líneas 1–6 y 8–N igual se procesan y la 7 queda marcada
con su error.

**Por qué un cursor.** Hay que invocar un procedimiento por fila y aislar el resultado de cada una
(procesada o con el mensaje de error); eso es procesamiento secuencial que una sola sentencia
orientada a conjuntos no puede expresar. Se declara explícitamente que los reportes (stock por
categoría, bajo stock) **no** usarán cursor, porque se resuelven mejor con `GROUP BY` y vistas.

### Transacciones

Ya implementadas en `sp_CrearProducto`, `sp_RegistrarEntrada` y `sp_RegistrarSalida`
(`XACT_ABORT ON`, `TRY/CATCH`, `ROLLBACK` y `THROW` del error original, con bloqueo `UPDLOCK/HOLDLOCK`
para evitar condiciones de carrera sobre el stock). La importación masiva reutiliza este mecanismo.

## 7. Alcance actual y pendientes

Implementado: inventario (CRUD y búsqueda), movimientos con historial, proveedores (alta, listado,
desactivación), reportes, validación en cliente y servidor, manejo central de errores.

Pendiente o fuera del alcance de este avance: autenticación y roles, paginación de listados,
reactivación de productos y proveedores desactivados, edición de proveedores desde la interfaz
(la ruta `PUT` ya existe en la API), el trigger y el cursor descritos arriba, y CORS restringido a un
origen en producción.
