# Bodega de Computadores

Aplicación Full Stack para controlar el inventario de una bodega de computadores: productos, stock por
ubicación, entradas y salidas (Kardex), proveedores y reportes. Taller de Bases de Datos – avance 60 %.

```
Navegador ──▶ frontend (React + Vite, :5173) ──HTTP/JSON /api──▶ backend (Node + Express, :3000) ──▶ SQL Server
                  solo interfaz                                   API, validación y lógica          SQL explícito
                                                                  (driver mssql, sin ORM)           vistas y SP
```

| Carpeta | Contenido |
|---|---|
| `backend/` | API REST (Express). **Único** componente que se conecta a SQL Server. |
| `frontend/` | Interfaz React. Solo consume la API; no conoce credenciales ni SQL. |
| `database/` | Scripts SQL: base completa, pruebas y migración. |
| `docs/` | Documentación del modelo, objetos SQL, pruebas y propuesta para la entrega final. |

## Cómo ejecutarlo

Requisitos: Node.js 18 o superior, SQL Server (Express sirve) y el controlador ODBC 18
para SQL Server. En Windows, la configuración incluida usa autenticación integrada y la
instancia local `(local)`, por lo que no requiere habilitar TCP/IP.

**1. Base de datos.** Abre `database/01_base_datos.sql` en SSMS y ejecútalo completo (crea la base
`BodegaComputadores`, tablas, datos de ejemplo, vistas y procedimientos). También sirve:
`sqlcmd -S localhost -U sa -i database/01_base_datos.sql -f 65001`.
Si ya habías creado la base con la versión anterior del script, ejecuta solo `database/migracion_correcciones.sql`.

**2. Backend.**
```bash
cd backend
# Windows PowerShell:
Copy-Item .env.example .env
npm install
npm run dev               # http://localhost:3000/api/health
npm test                  # 21 pruebas automáticas (no necesitan la base)
```

En Windows, el `.env.example` usa autenticación integrada contra la instancia local `(local)`.
Se necesita tener instalado **ODBC Driver 18 for SQL Server**. Si usas otra instancia o
autenticación SQL, ajusta `DB_SERVER`, `DB_TRUSTED`, `DB_USER` y `DB_PASSWORD`.

**3. Frontend.**
```bash
cd frontend
npm install
npm run dev               # http://localhost:5173
```

Más detalle en [`docs/documentacion.md`](docs/documentacion.md).
