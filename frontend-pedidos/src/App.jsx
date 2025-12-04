import { useState } from 'react';
import Sidebar from './components/Sidebar';
import Clientes from './components/Clientes';
import Libros from './components/Libros';
import Pedidos from './components/Pedidos';
import Reportes from './components/Reportes';
import { Menu } from 'lucide-react';

function App() {
  const [activeTab, setActiveTab] = useState('pedidos');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Títulos dinámicos
  const titles = {
    pedidos: 'Gestión de Pedidos',
    clientes: 'Directorio de Clientes',
    libros: 'Inventario & Precios',
    reportes: 'Reportes de Ventas'
  };

  return (
    <div className="min-h-screen bg-slate-50 flex">
      {/* Sidebar Desktop */}
      <Sidebar activeTab={activeTab} setActiveTab={setActiveTab} />

      {/* Contenido Principal */}
      <main className="flex-1 md:ml-64 transition-all duration-300">
        
        {/* Header Móvil */}
        <div className="md:hidden bg-slate-900 text-white p-4 flex justify-between items-center shadow-md">
          <h1 className="font-bold">Oracle OMS</h1>
          <button onClick={() => setMobileMenuOpen(!mobileMenuOpen)}>
            <Menu />
          </button>
        </div>

        {/* Menú Móvil (Dropdown simple) */}
        {mobileMenuOpen && (
          <div className="md:hidden bg-slate-800 text-white p-2">
            {['pedidos', 'clientes', 'libros', 'reportes'].map(tab => (
              <button key={tab} 
                onClick={() => { setActiveTab(tab); setMobileMenuOpen(false); }}
                className="block w-full text-left p-3 capitalize border-b border-slate-700 last:border-0">
                {tab}
              </button>
            ))}
          </div>
        )}

        {/* Header de Página */}
        <header className="bg-white border-b border-slate-200 px-8 py-6 sticky top-0 z-40 bg-opacity-90 backdrop-blur-sm">
          <h2 className="text-2xl font-bold text-slate-800">{titles[activeTab]}</h2>
          <p className="text-slate-500 text-sm mt-1">Sistema de gestión integrado con Oracle Database</p>
        </header>

        {/* Área de Contenido con Padding */}
        <div className="p-6 md:p-8 max-w-7xl mx-auto animate-fadeIn">
          {activeTab === 'clientes' && <Clientes />}
          {activeTab === 'libros' && <Libros />}
          {activeTab === 'pedidos' && <Pedidos />}
          {activeTab === 'reportes' && <Reportes />}
        </div>
      </main>
    </div>
  );
}

export default App;