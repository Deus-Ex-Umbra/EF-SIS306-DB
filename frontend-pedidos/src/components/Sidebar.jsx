import { Users, BookOpen, ShoppingCart, BarChart3, Package } from 'lucide-react';

export default function Sidebar({ activeTab, setActiveTab }) {
  const menuItems = [
    { id: 'pedidos', label: 'Pedidos', icon: ShoppingCart },
    { id: 'clientes', label: 'Clientes', icon: Users },
    { id: 'libros', label: 'Inventario Libros', icon: BookOpen },
    { id: 'reportes', label: 'Reportes', icon: BarChart3 },
  ];

  return (
    <aside className="w-64 bg-slate-900 text-slate-300 flex flex-col h-screen fixed left-0 top-0 shadow-xl z-50 hidden md:flex">
      {/* Logo */}
      <div className="p-6 flex items-center gap-3 text-white border-b border-slate-800">
        <div className="bg-indigo-600 p-2 rounded-lg">
          <Package size={24} />
        </div>
        <div>
          <h1 className="font-bold text-lg tracking-tight">Oracle OMS</h1>
          <p className="text-xs text-slate-400">v1.0.0</p>
        </div>
      </div>

      {/* Navegación */}
      <nav className="flex-1 p-4 space-y-2">
        {menuItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 group
                ${isActive 
                  ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-900/50' 
                  : 'hover:bg-slate-800 hover:text-white'}`}
            >
              <Icon size={20} className={isActive ? 'text-white' : 'text-slate-400 group-hover:text-white'} />
              <span className="font-medium">{item.label}</span>
            </button>
          );
        })}
      </nav>

      {/* Footer Sidebar */}
      <div className="p-4 border-t border-slate-800">
        <div className="flex items-center gap-3 px-4 py-3 bg-slate-800/50 rounded-lg">
          <div className="w-8 h-8 rounded-full bg-indigo-500 flex items-center justify-center text-white font-bold text-xs">
            Admin
          </div>
          <div className="overflow-hidden">
            <p className="text-sm text-white truncate font-medium">Vendedor</p>
            <p className="text-xs text-slate-400 truncate">Sede Central</p>
          </div>
        </div>
      </div>
    </aside>
  );
}