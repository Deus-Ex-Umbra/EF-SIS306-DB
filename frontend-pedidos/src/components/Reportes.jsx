import { useState, useEffect } from 'react';
import api from '../api';
import { TrendingUp, MapPin, DollarSign } from 'lucide-react';

export default function Reportes() {
  const [ventas, setVentas] = useState([]);

  useEffect(() => {
    api.get('/reportes/ventas-ciudad').then(res => setVentas(res.data));
  }, []);

  // Calcular totales
  const totalIngresos = ventas.reduce((acc, curr) => acc + curr.TOTAL_VENTAS, 0);
  const totalPedidos = ventas.reduce((acc, curr) => acc + curr.PEDIDOS, 0);
  const ciudadTop = ventas.length > 0 ? ventas[0].NOMBRE_CIUDAD : 'N/A';

  const StatCard = ({ title, value, icon: Icon, color }) => (
    <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-200 flex items-center gap-4">
      <div className={`p-3 rounded-full ${color} bg-opacity-10`}>
        <Icon className={color.replace('bg-', 'text-')} size={24} />
      </div>
      <div>
        <p className="text-sm text-slate-500 font-medium">{title}</p>
        <p className="text-2xl font-bold text-slate-800">{value}</p>
      </div>
    </div>
  );

  return (
    <div className="space-y-8">
      {/* KPIs */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatCard title="Ingresos Totales" value={`$${totalIngresos.toLocaleString()}`} icon={DollarSign} color="bg-emerald-500" />
        <StatCard title="Pedidos Totales" value={totalPedidos} icon={TrendingUp} color="bg-blue-500" />
        <StatCard title="Ciudad Top Ventas" value={ciudadTop} icon={MapPin} color="bg-indigo-500" />
      </div>

      {/* Tabla Detallada */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="px-8 py-5 border-b border-slate-100">
          <h3 className="font-bold text-slate-800 text-lg">Desempeño por Ciudad</h3>
        </div>
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-50 text-slate-500 text-sm uppercase tracking-wider">
              <th className="p-4 pl-8 font-semibold">Ciudad / Región</th>
              <th className="p-4 text-center font-semibold">Pedidos</th>
              <th className="p-4 font-semibold w-1/3">Barra de Progreso</th>
              <th className="p-4 pr-8 text-right font-semibold">Ventas Totales</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {ventas.map((v, i) => {
              const porcentaje = (v.TOTAL_VENTAS / totalIngresos) * 100;
              return (
                <tr key={i} className="hover:bg-slate-50 transition-colors">
                  <td className="p-4 pl-8 font-medium text-slate-700">{v.NOMBRE_CIUDAD}</td>
                  <td className="p-4 text-center text-slate-600">{v.PEDIDOS}</td>
                  <td className="p-4">
                    <div className="w-full bg-slate-100 rounded-full h-2.5 overflow-hidden">
                      <div className="bg-indigo-600 h-2.5 rounded-full" style={{ width: `${porcentaje}%` }}></div>
                    </div>
                  </td>
                  <td className="p-4 pr-8 text-right font-bold text-slate-800">
                    ${v.TOTAL_VENTAS.toLocaleString()}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}