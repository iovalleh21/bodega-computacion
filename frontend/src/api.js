// Cliente HTTP único. El frontend NUNCA toca SQL Server: solo habla con la API del backend.
// En desarrollo, Vite redirige /api a http://localhost:3000 (ver vite.config.js).
// Si el backend corre en otro servidor, define VITE_API_URL (ver .env.example).
const BASE = (import.meta.env.VITE_API_URL || '/api').replace(/\/$/, '');

// Si la API responde error, lanza Error con el mensaje del backend
async function request(path, options = {}) {
  const res = await fetch(`${BASE}${path}`, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
    body: options.body ? JSON.stringify(options.body) : undefined,
  });
  let data = null;
  try { data = await res.json(); } catch { /* respuesta sin cuerpo */ }
  if (!res.ok) {
    const err = new Error(data?.error || `Error ${res.status}`);
    err.status = res.status;
    throw err;
  }
  return data;
}

const qs = (obj) => {
  const p = new URLSearchParams();
  Object.entries(obj).forEach(([k, v]) => { if (v !== '' && v != null) p.append(k, v); });
  const s = p.toString();
  return s ? `?${s}` : '';
};

export const api = {
  productos: {
    listar: (filtros = {}) => request(`/productos${qs(filtros)}`),
    crear: (body) => request('/productos', { method: 'POST', body }),
    actualizar: (id, body) => request(`/productos/${id}`, { method: 'PUT', body }),
    desactivar: (id) => request(`/productos/${id}`, { method: 'DELETE' }),
    categorias: () => request('/productos/catalogos/categorias'),
    marcas: () => request('/productos/catalogos/marcas'),
    ubicaciones: () => request('/productos/catalogos/ubicaciones'),
  },
  proveedores: {
    listar: () => request('/proveedores'),
    crear: (body) => request('/proveedores', { method: 'POST', body }),
    desactivar: (id) => request(`/proveedores/${id}`, { method: 'DELETE' }),
  },
  movimientos: {
    entrada: (body) => request('/movimientos/entrada', { method: 'POST', body }),
    salida: (body) => request('/movimientos/salida', { method: 'POST', body }),
    listar: (filtros) => request(`/movimientos${qs(filtros)}`),
  },
  reportes: {
    bajoStock: () => request('/reportes/bajo-stock'),
    stockPorCategoria: () => request('/reportes/stock-por-categoria'),
  },
};
