import { useState } from 'react';
import Inventario from './components/Inventario.jsx';
import Movimientos from './components/Movimientos.jsx';
import Proveedores from './components/Proveedores.jsx';

const VISTAS = [
  { id: 'inventario', etiqueta: 'Inventario', Componente: Inventario },
  { id: 'movimientos', etiqueta: 'Movimientos', Componente: Movimientos },
  { id: 'proveedores', etiqueta: 'Proveedores', Componente: Proveedores },
];

export default function App() {
  const [vista, setVista] = useState('inventario');
  const Actual = VISTAS.find((v) => v.id === vista).Componente;

  return (
    <div className="app">
      <header className="topbar">
        <h1>📦 Bodega de Computadores</h1>
        <nav>
          {VISTAS.map((v) => (
            <button key={v.id} className={vista === v.id ? 'tab activo' : 'tab'} onClick={() => setVista(v.id)}>
              {v.etiqueta}
            </button>
          ))}
        </nav>
      </header>
      <main><Actual /></main>
    </div>
  );
}