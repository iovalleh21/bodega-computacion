-- =====================================================================
-- Bodega de Computadores - Pruebas de los objetos SQL
-- Ejecutar DESPUES de 01_base_datos.sql, en una sola ejecucion (F5 en SSMS).
-- Usa dos productos de prueba (TEST-001 y TEST-002) y los elimina al final,
-- por lo que se puede repetir las veces que se necesite.
-- Cada caso imprime "OK" o "FALLO" junto con el codigo de error del SP.
--   Casos normales: A1 A2 C1 C2 D1 E1 E2
--   Casos limite  : B1 B2 D2 D3 E3
--   Casos de error: A3-A6 C3-C6 D4-D7 E4-E6
-- =====================================================================
USE [BodegaComputadores]
GO
SET NOCOUNT ON;

-- Limpieza previa (por si una ejecucion anterior quedo a medias). Siempre con WHERE.
DELETE FROM dbo.Movimiento WHERE ProductoId IN (SELECT ProductoId FROM dbo.Producto WHERE SKU IN (N'TEST-001', N'TEST-002'));
DELETE FROM dbo.Stock      WHERE ProductoId IN (SELECT ProductoId FROM dbo.Producto WHERE SKU IN (N'TEST-001', N'TEST-002'));
DELETE FROM dbo.Producto   WHERE SKU IN (N'TEST-001', N'TEST-002');

DECLARE @p1 INT, @p2 INT, @stock INT, @baja BIT, @n INT, @antes INT, @despues INT, @faltante INT;
DECLARE @hoy DATE = CONVERT(DATE, SYSDATETIME());

PRINT '=== A. sp_CrearProducto ===';
-- A1 normal: producto con stock minimo 5
EXEC dbo.sp_CrearProducto @SKU = N'TEST-001', @Nombre = N'Producto de prueba 1', @CategoriaId = 1, @MarcaId = 1,
                          @PrecioCosto = 1000, @PrecioVenta = 1500, @StockMinimo = 5;
SELECT @p1 = ProductoId FROM dbo.Producto WHERE SKU = N'TEST-001';
PRINT CONCAT(IIF(@p1 IS NOT NULL, 'OK     ', 'FALLO  '), 'A1 crear producto con minimo 5 -> ProductoId ', @p1);

-- A2 normal: producto sin umbral de reposicion (minimo 0)
EXEC dbo.sp_CrearProducto @SKU = N'TEST-002', @Nombre = N'Producto de prueba 2', @CategoriaId = 1, @MarcaId = 1,
                          @PrecioCosto = 0, @PrecioVenta = 0, @StockMinimo = 0;
SELECT @p2 = ProductoId FROM dbo.Producto WHERE SKU = N'TEST-002';
PRINT CONCAT(IIF(@p2 IS NOT NULL, 'OK     ', 'FALLO  '), 'A2 crear producto con minimo 0 y precios 0 -> ProductoId ', @p2);

-- A3 error: SKU duplicado (50003)
BEGIN TRY
    EXEC dbo.sp_CrearProducto @SKU = N'TEST-001', @Nombre = N'Duplicado', @CategoriaId = 1, @MarcaId = 1, @PrecioCosto = 1, @PrecioVenta = 1;
    PRINT 'FALLO  A3 SKU duplicado: debia lanzar 50003';
END TRY
BEGIN CATCH
    PRINT CONCAT(IIF(ERROR_NUMBER() = 50003, 'OK     ', 'FALLO  '), 'A3 SKU duplicado -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH

-- A4 error: precio negativo (50002)
BEGIN TRY
    EXEC dbo.sp_CrearProducto @SKU = N'TEST-003', @Nombre = N'Precio negativo', @CategoriaId = 1, @MarcaId = 1, @PrecioCosto = -1, @PrecioVenta = 1;
    PRINT 'FALLO  A4 precio negativo: debia lanzar 50002';
END TRY
BEGIN CATCH
    PRINT CONCAT(IIF(ERROR_NUMBER() = 50002, 'OK     ', 'FALLO  '), 'A4 precio negativo -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH

-- A5 error: SKU en blanco (50001)
BEGIN TRY
    EXEC dbo.sp_CrearProducto @SKU = N'   ', @Nombre = N'Sin SKU', @CategoriaId = 1, @MarcaId = 1, @PrecioCosto = 1, @PrecioVenta = 1;
    PRINT 'FALLO  A5 SKU en blanco: debia lanzar 50001';
END TRY
BEGIN CATCH
    PRINT CONCAT(IIF(ERROR_NUMBER() = 50001, 'OK     ', 'FALLO  '), 'A5 SKU en blanco -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH

-- A6 error: categoria inexistente (50004)
BEGIN TRY
    EXEC dbo.sp_CrearProducto @SKU = N'TEST-004', @Nombre = N'Categoria falsa', @CategoriaId = 99999, @MarcaId = 1, @PrecioCosto = 1, @PrecioVenta = 1;
    PRINT 'FALLO  A6 categoria inexistente: debia lanzar 50004';
END TRY
BEGIN CATCH
    PRINT CONCAT(IIF(ERROR_NUMBER() = 50004, 'OK     ', 'FALLO  '), 'A6 categoria inexistente -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH

PRINT '=== B. Vista vw_StockProducto (BajoStock) ===';
-- B1 limite: stock 0 con minimo 5 => bajo stock
SELECT @stock = StockTotal, @baja = BajoStock FROM dbo.vw_StockProducto WHERE ProductoId = @p1;
PRINT CONCAT(IIF(@stock = 0 AND @baja = 1, 'OK     ', 'FALLO  '), 'B1 stock 0, minimo 5 -> BajoStock = ', @baja);
-- B2 limite: stock 0 con minimo 0 => NO es bajo stock (producto sin umbral)
SELECT @stock = StockTotal, @baja = BajoStock FROM dbo.vw_StockProducto WHERE ProductoId = @p2;
PRINT CONCAT(IIF(@stock = 0 AND @baja = 0, 'OK     ', 'FALLO  '), 'B2 stock 0, minimo 0 -> BajoStock = ', @baja);

PRINT '=== C. sp_RegistrarEntrada ===';
-- C1 normal: entrada de 10 unidades en A-01 con proveedor
EXEC dbo.sp_RegistrarEntrada @ProductoId = @p1, @UbicacionId = 1, @Cantidad = 10, @ProveedorId = 1, @Referencia = N'Prueba C1';
SELECT @stock = StockTotal, @baja = BajoStock FROM dbo.vw_StockProducto WHERE ProductoId = @p1;
PRINT CONCAT(IIF(@stock = 10 AND @baja = 0, 'OK     ', 'FALLO  '), 'C1 entrada de 10 -> StockTotal ', @stock, ', BajoStock ', @baja);
-- C2 normal: el mismo producto en otra ubicacion, sin proveedor (Stock tiene PK compuesta)
EXEC dbo.sp_RegistrarEntrada @ProductoId = @p1, @UbicacionId = 2, @Cantidad = 1, @Referencia = N'Prueba C2';
SELECT @stock = StockTotal FROM dbo.vw_StockProducto WHERE ProductoId = @p1;
SELECT @n = COUNT(*) FROM dbo.Stock WHERE ProductoId = @p1;
PRINT CONCAT(IIF(@stock = 11 AND @n = 2, 'OK     ', 'FALLO  '), 'C2 entrada de 1 en otra ubicacion -> StockTotal ', @stock, ' en ', @n, ' ubicaciones');
-- C3 error: cantidad 0 (50010)
BEGIN TRY
    EXEC dbo.sp_RegistrarEntrada @ProductoId = @p1, @UbicacionId = 1, @Cantidad = 0;
    PRINT 'FALLO  C3 cantidad 0: debia lanzar 50010';
END TRY
BEGIN CATCH
    PRINT CONCAT(IIF(ERROR_NUMBER() = 50010, 'OK     ', 'FALLO  '), 'C3 cantidad 0 -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH
-- C4 error: producto inexistente (50011)
BEGIN TRY
    EXEC dbo.sp_RegistrarEntrada @ProductoId = 99999, @UbicacionId = 1, @Cantidad = 1;
    PRINT 'FALLO  C4 producto inexistente: debia lanzar 50011';
END TRY
BEGIN CATCH
    PRINT CONCAT(IIF(ERROR_NUMBER() = 50011, 'OK     ', 'FALLO  '), 'C4 producto inexistente -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH
-- C5 error: ubicacion inexistente (50012)
BEGIN TRY
    EXEC dbo.sp_RegistrarEntrada @ProductoId = @p1, @UbicacionId = 99999, @Cantidad = 1;
    PRINT 'FALLO  C5 ubicacion inexistente: debia lanzar 50012';
END TRY
BEGIN CATCH
    PRINT CONCAT(IIF(ERROR_NUMBER() = 50012, 'OK     ', 'FALLO  '), 'C5 ubicacion inexistente -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH
-- C6 error: proveedor inexistente (50013)
BEGIN TRY
    EXEC dbo.sp_RegistrarEntrada @ProductoId = @p1, @UbicacionId = 1, @Cantidad = 1, @ProveedorId = 99999;
    PRINT 'FALLO  C6 proveedor inexistente: debia lanzar 50013';
END TRY
BEGIN CATCH
    PRINT CONCAT(IIF(ERROR_NUMBER() = 50013, 'OK     ', 'FALLO  '), 'C6 proveedor inexistente -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH

PRINT '=== D. sp_RegistrarSalida ===';
-- D1 normal: salida de 5 desde A-01 (quedan 5 + 1 = 6)
EXEC dbo.sp_RegistrarSalida @ProductoId = @p1, @UbicacionId = 1, @Cantidad = 5, @Referencia = N'Prueba D1';
SELECT @stock = StockTotal, @baja = BajoStock FROM dbo.vw_StockProducto WHERE ProductoId = @p1;
PRINT CONCAT(IIF(@stock = 6 AND @baja = 0, 'OK     ', 'FALLO  '), 'D1 salida de 5 -> StockTotal ', @stock, ', BajoStock ', @baja);
-- D2 limite: dejar el stock EXACTAMENTE en el minimo (5) => ya es bajo stock
EXEC dbo.sp_RegistrarSalida @ProductoId = @p1, @UbicacionId = 2, @Cantidad = 1, @Referencia = N'Prueba D2';
SELECT @stock = StockTotal, @baja = BajoStock FROM dbo.vw_StockProducto WHERE ProductoId = @p1;
PRINT CONCAT(IIF(@stock = 5 AND @baja = 1, 'OK     ', 'FALLO  '), 'D2 stock igual al minimo -> StockTotal ', @stock, ', BajoStock ', @baja);
-- D3 limite: sacar todo lo que queda en A-01 (5 -> 0); el CHECK Cantidad >= 0 lo permite
EXEC dbo.sp_RegistrarSalida @ProductoId = @p1, @UbicacionId = 1, @Cantidad = 5, @Referencia = N'Prueba D3';
SELECT @stock = StockTotal FROM dbo.vw_StockProducto WHERE ProductoId = @p1;
PRINT CONCAT(IIF(@stock = 0, 'OK     ', 'FALLO  '), 'D3 salida del total disponible -> StockTotal ', @stock);
-- D4 error: stock insuficiente (50023). Se comprueba ademas que NO queda registro (rollback)
SELECT @antes = COUNT(*) FROM dbo.Movimiento WHERE ProductoId = @p1;
BEGIN TRY
    EXEC dbo.sp_RegistrarSalida @ProductoId = @p1, @UbicacionId = 1, @Cantidad = 1;
    PRINT 'FALLO  D4 stock insuficiente: debia lanzar 50023';
END TRY
BEGIN CATCH
    PRINT CONCAT(IIF(ERROR_NUMBER() = 50023, 'OK     ', 'FALLO  '), 'D4 stock insuficiente -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH
SELECT @despues = COUNT(*) FROM dbo.Movimiento WHERE ProductoId = @p1;
SELECT @stock = StockTotal FROM dbo.vw_StockProducto WHERE ProductoId = @p1;
PRINT CONCAT(IIF(@antes = @despues AND @stock = 0, 'OK     ', 'FALLO  '), 'D7 rollback: movimientos ', @antes, ' -> ', @despues, ', StockTotal sigue en ', @stock);
-- D5 error: cantidad 0 (50020)
BEGIN TRY
    EXEC dbo.sp_RegistrarSalida @ProductoId = @p1, @UbicacionId = 1, @Cantidad = 0;
    PRINT 'FALLO  D5 cantidad 0: debia lanzar 50020';
END TRY
BEGIN CATCH
    PRINT CONCAT(IIF(ERROR_NUMBER() = 50020, 'OK     ', 'FALLO  '), 'D5 cantidad 0 -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH
-- D6 error: ubicacion inexistente (50022)
BEGIN TRY
    EXEC dbo.sp_RegistrarSalida @ProductoId = @p1, @UbicacionId = 99999, @Cantidad = 1;
    PRINT 'FALLO  D6 ubicacion inexistente: debia lanzar 50022';
END TRY
BEGIN CATCH
    PRINT CONCAT(IIF(ERROR_NUMBER() = 50022, 'OK     ', 'FALLO  '), 'D6 ubicacion inexistente -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH

PRINT '=== E. sp_MovimientosPorRango (vista vw_MovimientosDetalle) ===';
CREATE TABLE #hist (MovimientoId BIGINT, Fecha DATETIME2(0), Tipo CHAR(1), TipoDescripcion NVARCHAR(50), ProductoId INT,
                    SKU NVARCHAR(30), Producto NVARCHAR(150), Ubicacion NVARCHAR(50), Proveedor NVARCHAR(120),
                    Cantidad INT, Referencia NVARCHAR(200));
-- E1 normal/limite: desde = hasta = hoy incluye todo el dia (2 entradas + 3 salidas = 5)
INSERT INTO #hist EXEC dbo.sp_MovimientosPorRango @Desde = @hoy, @Hasta = @hoy, @Tipo = NULL;
SELECT @n = COUNT(*) FROM #hist WHERE SKU = N'TEST-001';
PRINT CONCAT(IIF(@n = 5, 'OK     ', 'FALLO  '), 'E1 rango de un solo dia -> ', @n, ' movimientos de TEST-001');
-- E2 normal: filtro por tipo
DELETE FROM #hist;
INSERT INTO #hist EXEC dbo.sp_MovimientosPorRango @Desde = @hoy, @Hasta = @hoy, @Tipo = 'E';
SELECT @n = COUNT(*) FROM #hist WHERE SKU = N'TEST-001';
PRINT CONCAT(IIF(@n = 2, 'OK     ', 'FALLO  '), 'E2 solo entradas -> ', @n);
DELETE FROM #hist;
INSERT INTO #hist EXEC dbo.sp_MovimientosPorRango @Desde = @hoy, @Hasta = @hoy, @Tipo = 'S';
SELECT @n = COUNT(*) FROM #hist WHERE SKU = N'TEST-001';
PRINT CONCAT(IIF(@n = 3, 'OK     ', 'FALLO  '), 'E2 solo salidas -> ', @n);
-- E3 limite: rango en el pasado lejano => resultado vacio, sin error
DELETE FROM #hist;
INSERT INTO #hist EXEC dbo.sp_MovimientosPorRango @Desde = '2000-01-01', @Hasta = '2000-01-02', @Tipo = NULL;
SELECT @n = COUNT(*) FROM #hist;
PRINT CONCAT(IIF(@n = 0, 'OK     ', 'FALLO  '), 'E3 rango sin movimientos -> ', @n, ' filas');
DROP TABLE #hist;
-- E4 error: desde posterior a hasta (50031)
BEGIN TRY
    EXEC dbo.sp_MovimientosPorRango @Desde = '2026-12-31', @Hasta = '2026-01-01';
    PRINT 'FALLO  E4 rango invertido: debia lanzar 50031';
END TRY
BEGIN CATCH
    PRINT CONCAT(IIF(ERROR_NUMBER() = 50031, 'OK     ', 'FALLO  '), 'E4 rango invertido -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH
-- E5 error: tipo invalido (50032)
BEGIN TRY
    EXEC dbo.sp_MovimientosPorRango @Desde = @hoy, @Hasta = @hoy, @Tipo = 'X';
    PRINT 'FALLO  E5 tipo invalido: debia lanzar 50032';
END TRY
BEGIN CATCH
    PRINT CONCAT(IIF(ERROR_NUMBER() = 50032, 'OK     ', 'FALLO  '), 'E5 tipo invalido -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH
-- E6 error: fechas nulas (50030)
BEGIN TRY
    EXEC dbo.sp_MovimientosPorRango @Desde = NULL, @Hasta = NULL;
    PRINT 'FALLO  E6 fechas nulas: debia lanzar 50030';
END TRY
BEGIN CATCH
    PRINT CONCAT(IIF(ERROR_NUMBER() = 50030, 'OK     ', 'FALLO  '), 'E6 fechas nulas -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH

PRINT '=== F. Vista vw_ProductosBajoStock ===';
-- TEST-001 quedo en 0 con minimo 5 => aparece con Faltante 5; TEST-002 (minimo 0) no aparece
SELECT @faltante = Faltante FROM dbo.vw_ProductosBajoStock WHERE ProductoId = @p1;
SELECT @n = COUNT(*) FROM dbo.vw_ProductosBajoStock WHERE ProductoId = @p2;
PRINT CONCAT(IIF(@faltante = 5 AND @n = 0, 'OK     ', 'FALLO  '), 'F1 TEST-001 listado con Faltante ', @faltante, '; TEST-002 listado: ', @n, ' vez/veces');

-- Evidencia visual: lo que consume la aplicacion
SELECT * FROM dbo.vw_ProductosBajoStock ORDER BY Faltante DESC;
SELECT Categoria, COUNT(*) AS Productos, SUM(StockTotal) AS StockTotal
FROM dbo.vw_StockProducto WHERE Activo = 1 GROUP BY Categoria ORDER BY Categoria;
SELECT MovimientoId, Fecha, TipoDescripcion, SKU, Ubicacion, Proveedor, Cantidad, Referencia
FROM dbo.vw_MovimientosDetalle WHERE SKU = N'TEST-001' ORDER BY MovimientoId;

-- Limpieza final: elimina solo los datos de prueba
DELETE FROM dbo.Movimiento WHERE ProductoId IN (SELECT ProductoId FROM dbo.Producto WHERE SKU IN (N'TEST-001', N'TEST-002'));
DELETE FROM dbo.Stock      WHERE ProductoId IN (SELECT ProductoId FROM dbo.Producto WHERE SKU IN (N'TEST-001', N'TEST-002'));
DELETE FROM dbo.Producto   WHERE SKU IN (N'TEST-001', N'TEST-002');
PRINT '=== Datos de prueba eliminados ===';
GO
