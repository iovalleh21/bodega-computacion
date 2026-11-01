-- =====================================================================
-- Migracion de correcciones (solo para bases YA creadas con el script anterior)
-- Si creas la base desde 01_base_datos.sql NO necesitas ejecutar este archivo.
--  * BajoStock: un producto con StockMinimo = 0 ya no se marca como "bajo stock"
--  * sp_CrearProducto: el mensaje de SKU duplicado aclara que puede estar desactivado
-- Es seguro ejecutarlo mas de una vez (CREATE OR ALTER).
-- =====================================================================
USE [BodegaComputadores]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW [dbo].[vw_StockProducto] AS
SELECT  p.ProductoId, p.SKU, p.Nombre,
        p.CategoriaId, c.Nombre AS Categoria,
        p.MarcaId,     m.Nombre AS Marca,
        p.PrecioCosto, p.PrecioVenta, p.StockMinimo, p.Activo,
        COALESCE(SUM(s.Cantidad), 0) AS StockTotal,
        CAST(CASE WHEN p.StockMinimo > 0 AND COALESCE(SUM(s.Cantidad), 0) <= p.StockMinimo THEN 1 ELSE 0 END AS BIT) AS BajoStock
FROM    Producto p
JOIN    Categoria c ON c.CategoriaId = p.CategoriaId
JOIN    Marca     m ON m.MarcaId     = p.MarcaId
LEFT JOIN Stock   s ON s.ProductoId  = p.ProductoId
GROUP BY p.ProductoId, p.SKU, p.Nombre, p.CategoriaId, c.Nombre,
         p.MarcaId, m.Nombre, p.PrecioCosto, p.PrecioVenta, p.StockMinimo, p.Activo;
GO
CREATE OR ALTER VIEW [dbo].[vw_ProductosBajoStock] AS
SELECT  ProductoId, SKU, Nombre, Categoria, Marca, StockMinimo, StockTotal,
        (StockMinimo - StockTotal) AS Faltante
FROM    vw_StockProducto
WHERE   Activo = 1 AND BajoStock = 1;
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_CrearProducto]
    @SKU NVARCHAR(30), @Nombre NVARCHAR(150),
    @CategoriaId INT, @MarcaId INT,
    @PrecioCosto DECIMAL(12,2), @PrecioVenta DECIMAL(12,2), @StockMinimo INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF LTRIM(RTRIM(ISNULL(@SKU,N''))) = N'' OR LTRIM(RTRIM(ISNULL(@Nombre,N''))) = N''
            THROW 50001, 'SKU y Nombre son obligatorios.', 1;
        IF @PrecioCosto < 0 OR @PrecioVenta < 0 OR @StockMinimo < 0
            THROW 50002, 'Precios y stock mínimo no pueden ser negativos.', 1;
        IF EXISTS (SELECT 1 FROM Producto WITH (UPDLOCK, HOLDLOCK) WHERE SKU = @SKU)
            THROW 50003, 'Ya existe un producto con ese SKU (puede estar desactivado).', 1;
        IF NOT EXISTS (SELECT 1 FROM Categoria WHERE CategoriaId = @CategoriaId)
           OR NOT EXISTS (SELECT 1 FROM Marca WHERE MarcaId = @MarcaId)
            THROW 50004, 'Categoría o marca inexistente.', 1;

        INSERT INTO Producto (SKU, Nombre, CategoriaId, MarcaId, PrecioCosto, PrecioVenta, StockMinimo)
        VALUES (@SKU, @Nombre, @CategoriaId, @MarcaId, @PrecioCosto, @PrecioVenta, @StockMinimo);

        DECLARE @Id INT = SCOPE_IDENTITY();
        COMMIT TRANSACTION;
        SELECT @Id AS ProductoId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;   -- re-lanza el error original (conserva el número 5xxxx)
    END CATCH
END;
GO
