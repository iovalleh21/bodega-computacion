-- =====================================================================
-- Bodega de Computadores - Script completo (UTF-8)
-- Crea la base, tablas, restricciones, datos de ejemplo, vistas y
-- procedimientos almacenados. Ejecutar UNA vez sobre una instancia donde
-- la base BodegaComputadores todavia no exista.
-- =====================================================================
USE [master]
GO
CREATE DATABASE [BodegaComputadores]
GO
USE [BodegaComputadores]
GO
/****** Objeto: Table [dbo].[Categoria] Fecha de script: 01-11-2026 15:06:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Categoria](
	[CategoriaId] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](80) NOT NULL,
 CONSTRAINT [PK_Categoria] PRIMARY KEY CLUSTERED 
(
	[CategoriaId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Marca] Fecha de script: 01-11-2026 15:06:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Marca](
	[MarcaId] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](80) NOT NULL,
 CONSTRAINT [PK_Marca] PRIMARY KEY CLUSTERED 
(
	[MarcaId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Producto] Fecha de script: 01-11-2026 15:06:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Producto](
	[ProductoId] [int] IDENTITY(1,1) NOT NULL,
	[SKU] [nvarchar](30) NOT NULL,
	[Nombre] [nvarchar](150) NOT NULL,
	[CategoriaId] [int] NOT NULL,
	[MarcaId] [int] NOT NULL,
	[PrecioCosto] [decimal](12, 2) NOT NULL,
	[PrecioVenta] [decimal](12, 2) NOT NULL,
	[StockMinimo] [int] NOT NULL,
	[Activo] [bit] NOT NULL,
 CONSTRAINT [PK_Producto] PRIMARY KEY CLUSTERED 
(
	[ProductoId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Stock] Fecha de script: 01-11-2026 15:06:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Stock](
	[ProductoId] [int] NOT NULL,
	[UbicacionId] [int] NOT NULL,
	[Cantidad] [int] NOT NULL,
 CONSTRAINT [PK_Stock] PRIMARY KEY CLUSTERED 
(
	[ProductoId] ASC,
	[UbicacionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: View [dbo].[vw_StockProducto] Fecha de script: 01-11-2026 15:06:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Stock total por producto (JOINs + SUM). BajoStock = stock <= minimo,
-- salvo que el minimo sea 0 (producto sin umbral de reposicion) -----
CREATE   VIEW [dbo].[vw_StockProducto] AS
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
/****** Objeto: View [dbo].[vw_ProductosBajoStock] Fecha de script: 01-11-2026 15:06:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Productos activos con stock <= minimo (minimo > 0) ----------
CREATE   VIEW [dbo].[vw_ProductosBajoStock] AS
SELECT  ProductoId, SKU, Nombre, Categoria, Marca, StockMinimo, StockTotal,
        (StockMinimo - StockTotal) AS Faltante
FROM    vw_StockProducto
WHERE   Activo = 1 AND BajoStock = 1;
GO
/****** Objeto: Table [dbo].[Proveedor] Fecha de script: 01-11-2026 15:06:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Proveedor](
	[ProveedorId] [int] IDENTITY(1,1) NOT NULL,
	[Rut] [nvarchar](12) NOT NULL,
	[Nombre] [nvarchar](120) NOT NULL,
	[Email] [nvarchar](120) NULL,
	[Telefono] [nvarchar](30) NULL,
	[Activo] [bit] NOT NULL,
 CONSTRAINT [PK_Proveedor] PRIMARY KEY CLUSTERED 
(
	[ProveedorId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Ubicacion] Fecha de script: 01-11-2026 15:06:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Ubicacion](
	[UbicacionId] [int] IDENTITY(1,1) NOT NULL,
	[Codigo] [nvarchar](20) NOT NULL,
	[Descripcion] [nvarchar](120) NULL,
 CONSTRAINT [PK_Ubicacion] PRIMARY KEY CLUSTERED 
(
	[UbicacionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Movimiento] Fecha de script: 01-11-2026 15:06:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Movimiento](
	[MovimientoId] [bigint] IDENTITY(1,1) NOT NULL,
	[ProductoId] [int] NOT NULL,
	[UbicacionId] [int] NOT NULL,
	[ProveedorId] [int] NULL,
	[Tipo] [char](1) NOT NULL,
	[Cantidad] [int] NOT NULL,
	[Fecha] [datetime2](0) NOT NULL,
	[Referencia] [nvarchar](200) NULL,
 CONSTRAINT [PK_Movimiento] PRIMARY KEY CLUSTERED 
(
	[MovimientoId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: View [dbo].[vw_MovimientosDetalle] Fecha de script: 01-11-2026 15:06:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Kardex detallado --------------------------------------------
CREATE   VIEW [dbo].[vw_MovimientosDetalle] AS
SELECT  mv.MovimientoId, mv.Fecha, mv.Tipo,
        CASE mv.Tipo WHEN 'E' THEN N'Entrada' ELSE N'Salida' END AS TipoDescripcion,
        p.ProductoId, p.SKU, p.Nombre AS Producto,
        u.Codigo AS Ubicacion,
        pr.Nombre AS Proveedor,
        mv.Cantidad, mv.Referencia
FROM    Movimiento mv
JOIN    Producto  p  ON p.ProductoId  = mv.ProductoId
JOIN    Ubicacion u  ON u.UbicacionId = mv.UbicacionId
LEFT JOIN Proveedor pr ON pr.ProveedorId = mv.ProveedorId;
GO
SET IDENTITY_INSERT [dbo].[Categoria] ON 

INSERT [dbo].[Categoria] ([CategoriaId], [Nombre]) VALUES (4, N'Almacenamiento')
INSERT [dbo].[Categoria] ([CategoriaId], [Nombre]) VALUES (5, N'Componentes')
INSERT [dbo].[Categoria] ([CategoriaId], [Nombre]) VALUES (2, N'Monitores')
INSERT [dbo].[Categoria] ([CategoriaId], [Nombre]) VALUES (1, N'Notebooks')
INSERT [dbo].[Categoria] ([CategoriaId], [Nombre]) VALUES (3, N'Periféricos')
SET IDENTITY_INSERT [dbo].[Categoria] OFF
GO
SET IDENTITY_INSERT [dbo].[Marca] ON 

INSERT [dbo].[Marca] ([MarcaId], [Nombre]) VALUES (3, N'Dell')
INSERT [dbo].[Marca] ([MarcaId], [Nombre]) VALUES (2, N'HP')
INSERT [dbo].[Marca] ([MarcaId], [Nombre]) VALUES (5, N'Kingston')
INSERT [dbo].[Marca] ([MarcaId], [Nombre]) VALUES (1, N'Lenovo')
INSERT [dbo].[Marca] ([MarcaId], [Nombre]) VALUES (4, N'Logitech')
SET IDENTITY_INSERT [dbo].[Marca] OFF
GO
SET IDENTITY_INSERT [dbo].[Producto] ON 

INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (1, N'NB-LEN-001', N'Lenovo ThinkPad E14', 1, 1, CAST(550000.00 AS Decimal(12, 2)), CAST(699990.00 AS Decimal(12, 2)), 5, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (2, N'NB-HP-001', N'HP ProBook 450 G10', 1, 2, CAST(520000.00 AS Decimal(12, 2)), CAST(659990.00 AS Decimal(12, 2)), 5, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (3, N'NB-DEL-001', N'Dell Latitude 3540', 1, 3, CAST(580000.00 AS Decimal(12, 2)), CAST(729990.00 AS Decimal(12, 2)), 4, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (4, N'NB-LEN-002', N'Lenovo IdeaPad 3', 1, 1, CAST(380000.00 AS Decimal(12, 2)), CAST(499990.00 AS Decimal(12, 2)), 5, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (5, N'MN-DEL-001', N'Monitor Dell P2422H 24"', 2, 3, CAST(140000.00 AS Decimal(12, 2)), CAST(189990.00 AS Decimal(12, 2)), 6, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (6, N'MN-HP-001', N'Monitor HP M24f 24"', 2, 2, CAST(90000.00 AS Decimal(12, 2)), CAST(129990.00 AS Decimal(12, 2)), 6, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (7, N'MN-LEN-001', N'Monitor Lenovo L24 24"', 2, 1, CAST(85000.00 AS Decimal(12, 2)), CAST(119990.00 AS Decimal(12, 2)), 5, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (8, N'MN-DEL-002', N'Monitor Dell U2723QE 27" 4K', 2, 3, CAST(380000.00 AS Decimal(12, 2)), CAST(499990.00 AS Decimal(12, 2)), 3, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (9, N'PE-LOG-001', N'Teclado Logitech MX Keys', 3, 4, CAST(70000.00 AS Decimal(12, 2)), CAST(99990.00 AS Decimal(12, 2)), 8, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (10, N'PE-LOG-002', N'Mouse Logitech M185', 3, 4, CAST(8000.00 AS Decimal(12, 2)), CAST(12990.00 AS Decimal(12, 2)), 15, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (11, N'PE-LOG-003', N'Webcam Logitech C920', 3, 4, CAST(45000.00 AS Decimal(12, 2)), CAST(69990.00 AS Decimal(12, 2)), 5, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (12, N'PE-HP-001', N'Teclado HP USB', 3, 2, CAST(6000.00 AS Decimal(12, 2)), CAST(9990.00 AS Decimal(12, 2)), 10, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (13, N'AL-KIN-001', N'SSD Kingston A400 480GB', 4, 5, CAST(25000.00 AS Decimal(12, 2)), CAST(39990.00 AS Decimal(12, 2)), 10, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (14, N'AL-KIN-002', N'SSD Kingston NV2 1TB', 4, 5, CAST(45000.00 AS Decimal(12, 2)), CAST(64990.00 AS Decimal(12, 2)), 8, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (15, N'AL-KIN-003', N'Pendrive Kingston 64GB', 4, 5, CAST(5000.00 AS Decimal(12, 2)), CAST(8990.00 AS Decimal(12, 2)), 20, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (16, N'AL-KIN-004', N'SSD Kingston A400 960GB', 4, 5, CAST(42000.00 AS Decimal(12, 2)), CAST(59990.00 AS Decimal(12, 2)), 6, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (17, N'CO-KIN-001', N'RAM Kingston Fury 16GB DDR4', 5, 5, CAST(38000.00 AS Decimal(12, 2)), CAST(54990.00 AS Decimal(12, 2)), 6, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (18, N'CO-KIN-002', N'RAM Kingston Fury 32GB DDR5', 5, 5, CAST(90000.00 AS Decimal(12, 2)), CAST(129990.00 AS Decimal(12, 2)), 4, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (19, N'CO-DEL-001', N'Cargador Dell 65W', 5, 3, CAST(20000.00 AS Decimal(12, 2)), CAST(32990.00 AS Decimal(12, 2)), 5, 1)
INSERT [dbo].[Producto] ([ProductoId], [SKU], [Nombre], [CategoriaId], [MarcaId], [PrecioCosto], [PrecioVenta], [StockMinimo], [Activo]) VALUES (20, N'CO-HP-001', N'Cargador HP 65W', 5, 2, CAST(18000.00 AS Decimal(12, 2)), CAST(29990.00 AS Decimal(12, 2)), 5, 1)
SET IDENTITY_INSERT [dbo].[Producto] OFF
GO
SET IDENTITY_INSERT [dbo].[Proveedor] ON 

INSERT [dbo].[Proveedor] ([ProveedorId], [Rut], [Nombre], [Email], [Telefono], [Activo]) VALUES (1, N'76.111.111-1', N'TecnoImport SpA', N'ventas@tecnoimport.cl', N'+56 2 2111 1111', 1)
INSERT [dbo].[Proveedor] ([ProveedorId], [Rut], [Nombre], [Email], [Telefono], [Activo]) VALUES (2, N'76.222.222-2', N'Distribuidora Andes', N'contacto@andes.cl', N'+56 2 2222 2222', 1)
INSERT [dbo].[Proveedor] ([ProveedorId], [Rut], [Nombre], [Email], [Telefono], [Activo]) VALUES (3, N'76.333.333-3', N'CompuMayorista Ltda', N'info@compumayorista.cl', N'+56 2 2333 3333', 1)
INSERT [dbo].[Proveedor] ([ProveedorId], [Rut], [Nombre], [Email], [Telefono], [Activo]) VALUES (4, N'76.444.444-4', N'Global Hardware SA', N'ventas@globalhw.cl', N'+56 2 2444 4444', 1)
SET IDENTITY_INSERT [dbo].[Proveedor] OFF
GO
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (1, 1, 8)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (1, 2, 4)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (2, 1, 5)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (3, 1, 0)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (4, 1, 9)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (5, 3, 10)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (5, 4, 5)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (6, 3, 6)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (7, 3, 10)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (8, 3, 4)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (9, 5, 12)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (9, 6, 8)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (10, 5, 15)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (11, 5, 7)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (12, 5, 0)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (13, 6, 30)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (14, 6, 8)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (15, 6, 45)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (16, 6, 11)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (17, 2, 14)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (18, 2, 3)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (19, 2, 9)
INSERT [dbo].[Stock] ([ProductoId], [UbicacionId], [Cantidad]) VALUES (20, 2, 5)
GO
SET IDENTITY_INSERT [dbo].[Ubicacion] ON 

INSERT [dbo].[Ubicacion] ([UbicacionId], [Codigo], [Descripcion]) VALUES (1, N'A-01', N'Pasillo A, estante 1')
INSERT [dbo].[Ubicacion] ([UbicacionId], [Codigo], [Descripcion]) VALUES (2, N'A-02', N'Pasillo A, estante 2')
INSERT [dbo].[Ubicacion] ([UbicacionId], [Codigo], [Descripcion]) VALUES (3, N'B-01', N'Pasillo B, estante 1')
INSERT [dbo].[Ubicacion] ([UbicacionId], [Codigo], [Descripcion]) VALUES (4, N'B-02', N'Pasillo B, estante 2')
INSERT [dbo].[Ubicacion] ([UbicacionId], [Codigo], [Descripcion]) VALUES (5, N'C-01', N'Pasillo C, estante 1')
INSERT [dbo].[Ubicacion] ([UbicacionId], [Codigo], [Descripcion]) VALUES (6, N'C-02', N'Pasillo C, estante 2')
SET IDENTITY_INSERT [dbo].[Ubicacion] OFF
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [UQ_Categoria_Nombre] Fecha de script: 01-11-2026 15:06:23 ******/
ALTER TABLE [dbo].[Categoria] ADD  CONSTRAINT [UQ_Categoria_Nombre] UNIQUE NONCLUSTERED 
(
	[Nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [UQ_Marca_Nombre] Fecha de script: 01-11-2026 15:06:23 ******/
ALTER TABLE [dbo].[Marca] ADD  CONSTRAINT [UQ_Marca_Nombre] UNIQUE NONCLUSTERED 
(
	[Nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [IX_Mov_Fecha] Fecha de script: 01-11-2026 15:06:23 ******/
CREATE NONCLUSTERED INDEX [IX_Mov_Fecha] ON [dbo].[Movimiento]
(
	[Fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [IX_Mov_Producto] Fecha de script: 01-11-2026 15:06:23 ******/
CREATE NONCLUSTERED INDEX [IX_Mov_Producto] ON [dbo].[Movimiento]
(
	[ProductoId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [UQ_Producto_SKU] Fecha de script: 01-11-2026 15:06:23 ******/
ALTER TABLE [dbo].[Producto] ADD  CONSTRAINT [UQ_Producto_SKU] UNIQUE NONCLUSTERED 
(
	[SKU] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [UQ_Proveedor_Rut] Fecha de script: 01-11-2026 15:06:23 ******/
ALTER TABLE [dbo].[Proveedor] ADD  CONSTRAINT [UQ_Proveedor_Rut] UNIQUE NONCLUSTERED 
(
	[Rut] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Objeto: Index [UQ_Ubicacion_Codigo] Fecha de script: 01-11-2026 15:06:23 ******/
ALTER TABLE [dbo].[Ubicacion] ADD  CONSTRAINT [UQ_Ubicacion_Codigo] UNIQUE NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Movimiento] ADD  CONSTRAINT [DF_Mov_Fecha]  DEFAULT (sysdatetime()) FOR [Fecha]
GO
ALTER TABLE [dbo].[Producto] ADD  CONSTRAINT [DF_Producto_Min]  DEFAULT ((0)) FOR [StockMinimo]
GO
ALTER TABLE [dbo].[Producto] ADD  CONSTRAINT [DF_Producto_Activo]  DEFAULT ((1)) FOR [Activo]
GO
ALTER TABLE [dbo].[Proveedor] ADD  CONSTRAINT [DF_Proveedor_Activo]  DEFAULT ((1)) FOR [Activo]
GO
ALTER TABLE [dbo].[Stock] ADD  CONSTRAINT [DF_Stock_Cant]  DEFAULT ((0)) FOR [Cantidad]
GO
ALTER TABLE [dbo].[Movimiento]  WITH CHECK ADD  CONSTRAINT [FK_Mov_Producto] FOREIGN KEY([ProductoId])
REFERENCES [dbo].[Producto] ([ProductoId])
GO
ALTER TABLE [dbo].[Movimiento] CHECK CONSTRAINT [FK_Mov_Producto]
GO
ALTER TABLE [dbo].[Movimiento]  WITH CHECK ADD  CONSTRAINT [FK_Mov_Proveedor] FOREIGN KEY([ProveedorId])
REFERENCES [dbo].[Proveedor] ([ProveedorId])
GO
ALTER TABLE [dbo].[Movimiento] CHECK CONSTRAINT [FK_Mov_Proveedor]
GO
ALTER TABLE [dbo].[Movimiento]  WITH CHECK ADD  CONSTRAINT [FK_Mov_Ubicacion] FOREIGN KEY([UbicacionId])
REFERENCES [dbo].[Ubicacion] ([UbicacionId])
GO
ALTER TABLE [dbo].[Movimiento] CHECK CONSTRAINT [FK_Mov_Ubicacion]
GO
ALTER TABLE [dbo].[Producto]  WITH CHECK ADD  CONSTRAINT [FK_Producto_Categoria] FOREIGN KEY([CategoriaId])
REFERENCES [dbo].[Categoria] ([CategoriaId])
GO
ALTER TABLE [dbo].[Producto] CHECK CONSTRAINT [FK_Producto_Categoria]
GO
ALTER TABLE [dbo].[Producto]  WITH CHECK ADD  CONSTRAINT [FK_Producto_Marca] FOREIGN KEY([MarcaId])
REFERENCES [dbo].[Marca] ([MarcaId])
GO
ALTER TABLE [dbo].[Producto] CHECK CONSTRAINT [FK_Producto_Marca]
GO
ALTER TABLE [dbo].[Stock]  WITH CHECK ADD  CONSTRAINT [FK_Stock_Producto] FOREIGN KEY([ProductoId])
REFERENCES [dbo].[Producto] ([ProductoId])
GO
ALTER TABLE [dbo].[Stock] CHECK CONSTRAINT [FK_Stock_Producto]
GO
ALTER TABLE [dbo].[Stock]  WITH CHECK ADD  CONSTRAINT [FK_Stock_Ubicacion] FOREIGN KEY([UbicacionId])
REFERENCES [dbo].[Ubicacion] ([UbicacionId])
GO
ALTER TABLE [dbo].[Stock] CHECK CONSTRAINT [FK_Stock_Ubicacion]
GO
ALTER TABLE [dbo].[Movimiento]  WITH CHECK ADD  CONSTRAINT [CK_Mov_Cantidad] CHECK  (([Cantidad]>(0)))
GO
ALTER TABLE [dbo].[Movimiento] CHECK CONSTRAINT [CK_Mov_Cantidad]
GO
ALTER TABLE [dbo].[Movimiento]  WITH CHECK ADD  CONSTRAINT [CK_Mov_Tipo] CHECK  (([Tipo]='S' OR [Tipo]='E'))
GO
ALTER TABLE [dbo].[Movimiento] CHECK CONSTRAINT [CK_Mov_Tipo]
GO
ALTER TABLE [dbo].[Producto]  WITH CHECK ADD  CONSTRAINT [CK_Producto_Costo] CHECK  (([PrecioCosto]>=(0)))
GO
ALTER TABLE [dbo].[Producto] CHECK CONSTRAINT [CK_Producto_Costo]
GO
ALTER TABLE [dbo].[Producto]  WITH CHECK ADD  CONSTRAINT [CK_Producto_Min] CHECK  (([StockMinimo]>=(0)))
GO
ALTER TABLE [dbo].[Producto] CHECK CONSTRAINT [CK_Producto_Min]
GO
ALTER TABLE [dbo].[Producto]  WITH CHECK ADD  CONSTRAINT [CK_Producto_Venta] CHECK  (([PrecioVenta]>=(0)))
GO
ALTER TABLE [dbo].[Producto] CHECK CONSTRAINT [CK_Producto_Venta]
GO
ALTER TABLE [dbo].[Stock]  WITH CHECK ADD  CONSTRAINT [CK_Stock_Cantidad] CHECK  (([Cantidad]>=(0)))
GO
ALTER TABLE [dbo].[Stock] CHECK CONSTRAINT [CK_Stock_Cantidad]
GO
/****** Objeto: StoredProcedure [dbo].[sp_CrearProducto] Fecha de script: 01-11-2026 15:06:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- sp_CrearProducto --------------------------------------------
CREATE   PROCEDURE [dbo].[sp_CrearProducto]
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
/****** Objeto: StoredProcedure [dbo].[sp_MovimientosPorRango] Fecha de script: 01-11-2026 15:06:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- sp_MovimientosPorRango --------------------------------------
CREATE   PROCEDURE [dbo].[sp_MovimientosPorRango]
    @Desde DATE, @Hasta DATE, @Tipo CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Desde IS NULL OR @Hasta IS NULL
        THROW 50030, 'Debe indicar fecha desde y hasta.', 1;
    IF @Desde > @Hasta
        THROW 50031, 'Rango de fechas inválido: "desde" no puede ser posterior a "hasta".', 1;
    IF @Tipo IS NOT NULL AND @Tipo NOT IN ('E','S')
        THROW 50032, 'Tipo de movimiento inválido (use E o S).', 1;

    SELECT MovimientoId, Fecha, Tipo, TipoDescripcion, ProductoId, SKU, Producto,
           Ubicacion, Proveedor, Cantidad, Referencia
    FROM   vw_MovimientosDetalle
    WHERE  Fecha >= @Desde
      AND  Fecha <  DATEADD(DAY, 1, CAST(@Hasta AS DATETIME2))   -- incluye todo el día "hasta"
      AND  (@Tipo IS NULL OR Tipo = @Tipo)
    ORDER BY Fecha DESC, MovimientoId DESC;
END;
GO
/****** Objeto: StoredProcedure [dbo].[sp_RegistrarEntrada] Fecha de script: 01-11-2026 15:06:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- sp_RegistrarEntrada -----------------------------------------
CREATE   PROCEDURE [dbo].[sp_RegistrarEntrada]
    @ProductoId INT, @UbicacionId INT, @Cantidad INT,
    @ProveedorId INT = NULL, @Referencia NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Cantidad IS NULL OR @Cantidad <= 0
            THROW 50010, 'La cantidad debe ser mayor a cero.', 1;
        IF NOT EXISTS (SELECT 1 FROM Producto WHERE ProductoId = @ProductoId AND Activo = 1)
            THROW 50011, 'El producto no existe o está inactivo.', 1;
        IF NOT EXISTS (SELECT 1 FROM Ubicacion WHERE UbicacionId = @UbicacionId)
            THROW 50012, 'La ubicación no existe.', 1;
        IF @ProveedorId IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM Proveedor WHERE ProveedorId = @ProveedorId AND Activo = 1)
            THROW 50013, 'El proveedor no existe o está inactivo.', 1;

        -- UPDLOCK + HOLDLOCK: bloquea la fila (o el rango si no existe) para evitar carreras
        IF EXISTS (SELECT 1 FROM Stock WITH (UPDLOCK, HOLDLOCK)
                   WHERE ProductoId = @ProductoId AND UbicacionId = @UbicacionId)
            UPDATE Stock SET Cantidad = Cantidad + @Cantidad
            WHERE ProductoId = @ProductoId AND UbicacionId = @UbicacionId;
        ELSE
            INSERT INTO Stock (ProductoId, UbicacionId, Cantidad)
            VALUES (@ProductoId, @UbicacionId, @Cantidad);

        INSERT INTO Movimiento (ProductoId, UbicacionId, ProveedorId, Tipo, Cantidad, Referencia)
        VALUES (@ProductoId, @UbicacionId, @ProveedorId, 'E', @Cantidad, @Referencia);

        DECLARE @MovId BIGINT = SCOPE_IDENTITY();
        DECLARE @StockTotal INT = (SELECT SUM(Cantidad) FROM Stock WHERE ProductoId = @ProductoId);

        COMMIT TRANSACTION;
        SELECT @MovId AS MovimientoId, @StockTotal AS StockTotal;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
/****** Objeto: StoredProcedure [dbo].[sp_RegistrarSalida] Fecha de script: 01-11-2026 15:06:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- sp_RegistrarSalida ------------------------------------------
CREATE   PROCEDURE [dbo].[sp_RegistrarSalida]
    @ProductoId INT, @UbicacionId INT, @Cantidad INT, @Referencia NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Cantidad IS NULL OR @Cantidad <= 0
            THROW 50020, 'La cantidad debe ser mayor a cero.', 1;
        IF NOT EXISTS (SELECT 1 FROM Producto WHERE ProductoId = @ProductoId AND Activo = 1)
            THROW 50021, 'El producto no existe o está inactivo.', 1;
        IF NOT EXISTS (SELECT 1 FROM Ubicacion WHERE UbicacionId = @UbicacionId)
            THROW 50022, 'La ubicación no existe.', 1;

        -- Lectura con UPDLOCK: otra sesión no puede descontar la misma fila hasta el COMMIT
        DECLARE @Actual INT;
        SELECT @Actual = Cantidad
        FROM Stock WITH (UPDLOCK, HOLDLOCK)
        WHERE ProductoId = @ProductoId AND UbicacionId = @UbicacionId;

        IF @Actual IS NULL OR @Actual < @Cantidad
        BEGIN
            DECLARE @Msg NVARCHAR(200) = CONCAT(N'Stock insuficiente. Disponible: ', ISNULL(@Actual,0),
                                                N', solicitado: ', @Cantidad, N'.');
            THROW 50023, @Msg, 1;
        END

        UPDATE Stock SET Cantidad = Cantidad - @Cantidad
        WHERE ProductoId = @ProductoId AND UbicacionId = @UbicacionId;

        INSERT INTO Movimiento (ProductoId, UbicacionId, Tipo, Cantidad, Referencia)
        VALUES (@ProductoId, @UbicacionId, 'S', @Cantidad, @Referencia);

        DECLARE @MovId BIGINT = SCOPE_IDENTITY();
        DECLARE @StockTotal INT = (SELECT SUM(Cantidad) FROM Stock WHERE ProductoId = @ProductoId);

        COMMIT TRANSACTION;
        SELECT @MovId AS MovimientoId, @StockTotal AS StockTotal;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
