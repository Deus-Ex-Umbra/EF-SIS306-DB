import { useState, useEffect } from 'react';
import api from '../api';
import { UserPlus, Trash2, MapPin, Search, X, Edit2 } from 'lucide-react';

export default function Clientes() {
  const [clientes, setClientes] = useState([]);
  const [ciudades, setCiudades] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [loading, setLoading] = useState(false);

  // Estado del formulario
  const initialForm = { nombre: '', correo: '', direccion: '', id_ciudad: '' };
  const [form, setForm] = useState(initialForm);

  // Cargar datos al inicio
  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const [resCiudades, resClientes] = await Promise.all([
        api.get('/ciudades'),
        api.get('/clientes') 
      ]);
      setCiudades(resCiudades.data);
      setClientes(resClientes.data);
    } catch (err) {
      console.error("Error cargando datos", err);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      // 1. Crear Ubicación
      const resUbi = await api.post('/ubicaciones', { 
        id_ciudad: form.id_ciudad, 
        direccion: form.direccion 
      });
      
      // 2. Crear Cliente con la ID de ubicación retornada
      await api.post('/clientes', { 
        nombre: form.nombre, 
        correo: form.correo, 
        id_ubicacion: resUbi.data.id_ubicacion 
      });

      alert('✅ Cliente registrado con éxito');
      setShowModal(false);
      setForm(initialForm);
      fetchData(); // Recargar la tabla
    } catch (err) {
      alert('Error: ' + (err.response?.data?.error || err.message));
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!confirm('¿Estás seguro de eliminar este cliente?')) return;
    try {
      await api.delete(`/clientes/${id}`);
      // CORRECCIÓN: Usar ID_CLIENTE (Mayúscula) para filtrar
      setClientes(clientes.filter(c => c.ID_CLIENTE !== id)); 
      alert('🗑️ Cliente eliminado');
    } catch (err) {
      alert('Error al eliminar: ' + err.message);
    }
  };

  return (
    <div className="p-6 max-w-6xl mx-auto">
      
      {/* Encabezado y Botón de Acción */}
      <div className="flex flex-col md:flex-row justify-between items-center mb-6 gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">Gestión de Clientes</h1>
          <p className="text-slate-500 text-sm">Administra tus clientes y sus direcciones</p>
        </div>
        <button 
          onClick={() => setShowModal(true)}
          className="bg-indigo-600 hover:bg-indigo-700 text-white px-5 py-2.5 rounded-lg font-medium flex items-center gap-2 shadow-sm transition-all"
        >
          <UserPlus size={18} /> Nuevo Cliente
        </button>
      </div>

      {/* Tabla de Clientes */}
      <div className="bg-white rounded-xl shadow border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-xs uppercase text-slate-500 font-semibold">
                <th className="px-6 py-4">Nombre</th>
                <th className="px-6 py-4">Correo</th>
                <th className="px-6 py-4">Ubicación</th>
                <th className="px-6 py-4 text-center">Acciones</th>
              </tr>
            </thead>
            <tbody className="text-sm text-slate-700 divide-y divide-slate-100">
              {clientes.length > 0 ? (
                clientes.map((cliente) => (
                  /* CORRECCIÓN: key usa ID_CLIENTE */
                  <tr key={cliente.ID_CLIENTE} className="hover:bg-slate-50 transition-colors">
                    {/* CORRECCIÓN: cliente.NOMBRE (Mayúsculas) */}
                    <td className="px-6 py-4 font-medium">{cliente.NOMBRE}</td>
                    
                    {/* CORRECCIÓN: cliente.CORREO (Mayúsculas) */}
                    <td className="px-6 py-4 text-slate-500">{cliente.CORREO}</td>
                    
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-1.5 text-slate-600">
                        <MapPin size={14} className="text-indigo-500" />
                        {/* CORRECCIÓN: cliente.NOMBRE_CIUDAD y cliente.DIRECCION (Mayúsculas) */}
                        <span>{cliente.NOMBRE_CIUDAD || 'Ciudad'}, {cliente.DIRECCION || 'Dir'}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex justify-center gap-2">
                        <button 
                          /* CORRECCIÓN: Pasar ID_CLIENTE al borrar */
                          onClick={() => handleDelete(cliente.ID_CLIENTE)}
                          className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors tooltip"
                          title="Eliminar Cliente"
                        >
                          <Trash2 size={18} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="4" className="px-6 py-12 text-center text-slate-400">
                    No hay clientes registrados aún.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* MODAL (Formulario se mantiene igual, ya que usa el estado 'form' que sí está en minúsculas) */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl overflow-hidden animate-fadeIn">
            <div className="bg-indigo-600 px-6 py-4 flex justify-between items-center">
              <h3 className="text-white font-bold text-lg flex items-center gap-2">
                <UserPlus size={20} /> Registrar Nuevo Cliente
              </h3>
              <button onClick={() => setShowModal(false)} className="text-white/80 hover:text-white transition-colors">
                <X size={24} />
              </button>
            </div>
            <form onSubmit={handleSubmit} className="p-6 grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="col-span-2 md:col-span-1">
                <label className="text-sm font-medium text-slate-700 block mb-1">Nombre Completo</label>
                <input required className="input-field" placeholder="Ej: Juan Perez"
                  value={form.nombre} onChange={e => setForm({...form, nombre: e.target.value})} />
              </div>
              <div className="col-span-2 md:col-span-1">
                <label className="text-sm font-medium text-slate-700 block mb-1">Correo Electrónico</label>
                <input required type="email" className="input-field" placeholder="juan@empresa.com"
                  value={form.correo} onChange={e => setForm({...form, correo: e.target.value})} />
              </div>
              <div className="col-span-2">
                <div className="flex items-center gap-2 mb-3 pb-2 border-b border-slate-100">
                  <MapPin size={16} className="text-indigo-600" />
                  <span className="text-sm font-semibold text-slate-600">Dirección de Envío</span>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="text-xs text-slate-500 uppercase font-bold mb-1 block">Ciudad</label>
                    {/* Nota: Las ciudades en el <select> también usan mayúsculas según tu log anterior (ID_CIUDAD, NOMBRE_CIUDAD) */}
                    <select required className="input-field bg-white"
                      value={form.id_ciudad} onChange={e => setForm({...form, id_ciudad: e.target.value})}>
                      <option value="">Seleccionar...</option>
                      {ciudades.map(c => (
                        <option key={c.ID_CIUDAD} value={c.ID_CIUDAD}>{c.NOMBRE_CIUDAD}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="text-xs text-slate-500 uppercase font-bold mb-1 block">Dirección / Calle</label>
                    <input required className="input-field" placeholder="Av. Siempre Viva 123"
                      value={form.direccion} onChange={e => setForm({...form, direccion: e.target.value})} />
                  </div>
                </div>
              </div>
              <div className="col-span-2 pt-4 flex gap-3 justify-end border-t border-slate-100 mt-2">
                <button type="button" onClick={() => setShowModal(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg font-medium transition-colors">
                  Cancelar
                </button>
                <button type="submit" disabled={loading} className="px-6 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-bold shadow-md transition-all flex items-center gap-2">
                  {loading ? 'Guardando...' : 'Guardar Cliente'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
      <style>{`
        .input-field { @apply w-full border border-slate-300 rounded-lg px-3 py-2 text-slate-700 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all; }
        @keyframes fadeIn { from { opacity: 0; transform: scale(0.95); } to { opacity: 1; transform: scale(1); } }
        .animate-fadeIn { animation: fadeIn 0.2s ease-out; }
      `}</style>
    </div>
  );
}