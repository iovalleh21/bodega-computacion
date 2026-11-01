# Frontend – Bodega de Computadores

Interfaz en React + Vite. **No se conecta a SQL Server**: toda la información se obtiene y se
modifica a través de la API REST del backend (`../backend`), usando `src/api.js`.

## Ejecutar

```bash
npm install
npm run dev        # http://localhost:5173  (redirige /api a http://localhost:3000)
npm run lint
npm run build      # genera dist/
```

El backend debe estar corriendo (ver `../README.md`). Si la API está en otra URL, copia
`.env.example` a `.env` y define `VITE_API_URL`.

## Estructura

| Archivo | Responsabilidad |
|---|---|
| `src/api.js` | Único punto de comunicación con el backend (`fetch`) |
| `src/components/Inventario.jsx` | Listado, búsqueda, alta/edición/desactivación de productos |
| `src/components/ProductoForm.jsx` | Formulario modal de producto con validación en cliente |
| `src/components/Movimientos.jsx` | Registro de entradas/salidas e historial (Kardex) |
| `src/components/Proveedores.jsx` | Alta, listado y desactivación de proveedores |
| `src/components/Reportes.jsx` | Productos bajo stock y stock por categoría |
