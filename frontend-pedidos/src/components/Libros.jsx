import { useState, useEffect } from 'react';
import api from '../api';
import { BookOpen, TrendingUp, Plus, Tag, Edit3, Search } from 'lucide-react';

export default function Libros() {
  const [libros, setLibros] = useState([]);
  const [generos, setGeneros] = useState([]);
  const [form, setForm] = useState({ titulo: '', autor: '', precio: '', id_genero: '' });
  const [historial, setHistorial] = useState([]);
  const [modalOpen, setModalOpen] = useState(false);
  const [bookSelectedName, setBookSelectedName] = useState('');
  
  // Estado para búsqueda rápida en la tabla (cliente)
  const [searchTerm, setSearchTerm] = useState('');

  const fetchLibros = () => api.get('/libros').then(res => setLibros(res.data));
  
  useEffect(() => { 
    fetchLibros(); 
    api.get('/generos').then(res => setGeneros(res.data)); 
  }, []);

  const handleCreate = async (e) => {
    e.preventDefault();
    try {
      await api.post('/libros', form);
      alert('Libro creado correctamente');
      setForm({ titulo: '', autor: '', precio: '', id_genero: '' });
      fetchLibros();
    } catch (err) { 
      alert('Error: ' + (err.response?.data?.error || err.message)); 
    }
  };

  const handleUpdatePrecio = async (id, currentPrice, titulo) => {
    const p = prompt(`Actualizar precio para "${titulo}".\nPrecio actual: $${currentPrice}\n\nNuevo precio:`);
    if (!p) return;
    try { 
      await api.put('/libros/precio', { id_libro: id, nuevo_precio: p }); 
      fetchLibros(); 
    } catch (err) { alert('Error actualizando precio'); }
  };

  const verHistorial = async (id, titulo) => {
    try {
        const res = await api.get(`/libros/${id}/precios`);
        setHistorial(res.data);
        setBookSelectedName(titulo);
        setModalOpen(true);
    } catch (err) { alert('Error cargando historial'); }
  };

  // Filtro simple para la tabla
  const filteredLibros = libros.filter(l => 
    l.TITULO?.toLowerCase().includes(searchTerm.toLowerCase()) || 
    l.AUTOR?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="flex flex-col xl:flex-row gap-8 items-start">
      
      {/* 1. FORMULARIO LATERAL (Sticky) */}
      <div className="w-full xl:w-1/3 xl:sticky xl:top-24 z-10">
        <div className="bg-white rounded-2xl shadow-lg border border-slate-100 overflow-hidden">
          <div className="bg-slate-900 p-6 text-white">
            <h3 className="font-bold text-xl flex items-center gap-2">
              <Plus className="bg-white/20 p-1 rounded-lg" size={32}/> Registrar Libro
            </h3>
            <p className="text-slate-400 text-sm mt-1">Añade nuevos títulos al catálogo</p>
          </div>
          
          <form onSubmit={handleCreate} className="p-6 space-y-5">
            <div>
                <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Título de la Obra</label>
                <input className="w-full bg-slate-50 border border-slate-200 rounded-xl p-3 focus:ring-2 focus:ring-indigo-500 outline-none transition-all" 
                  placeholder="Ej: El Principito" required 
                  value={form.titulo} onChange={e => setForm({...form, titulo: e.target.value})} />
            </div>

            <div>
                <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Autor</label>
                <input className="w-full bg-slate-50 border border-slate-200 rounded-xl p-3 focus:ring-2 focus:ring-indigo-500 outline-none" 
                  placeholder="Ej: Antoine de Saint-Exupéry" required 
                  value={form.autor} onChange={e => setForm({...form, autor: e.target.value})} />
            </div>

            <div className="flex gap-4">
              <div className="w-1/2">
                <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Precio ($)</label>
                <input className="w-full bg-slate-50 border border-slate-200 rounded-xl p-3 font-mono" 
                  placeholder="0.00" type="number" required 
                  value={form.precio} onChange={e => setForm({...form, precio: e.target.value})} />
              </div>
              <div className="w-1/2">
                <label className="block text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Género</label>
                <div className="relative">
                  <select className="w-full bg-slate-50 border border-slate-200 rounded-xl p-3 appearance-none outline-none" required 
                      value={form.id_genero} onChange={e => setForm({...form, id_genero: e.target.value})}>
                      <option value="">Seleccionar...</option>
                      {generos.map(g => <option key={g.ID_GENERO} value={g.ID_GENERO}>{g.NOMBRE_GENERO}</option>)}
                  </select>
                  <div className="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none text-slate-500">
                    <svg className="w-4 h-4 fill-current" viewBox="0 0 20 20"><path d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"/></svg>
                  </div>
                </div>
              </div>
            </div>

            <button className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-4 rounded-xl shadow-lg shadow-indigo-200 transition-all active:scale-[0.98]">
                Guardar en Catálogo
            </button>
          </form>
        </div>
      </div>

      {/* 2. TABLA DE LIBROS (Reemplazo de Cards) */}
      <div className="w-full xl:w-2/3">
        
        {/* Barra de búsqueda superior */}
        <div className="bg-white p-4 rounded-t-2xl border border-b-0 border-slate-200 flex justify-between items-center">
            <h3 className="font-bold text-slate-700 flex items-center gap-2">
                <BookOpen size={20} className="text-indigo-600"/> Inventario ({libros.length})
            </h3>
            <div className="relative w-64">
                <Search size={16} className="absolute left-3 top-3 text-slate-400"/>
                <input 
                    type="text" 
                    placeholder="Buscar título o autor..." 
                    className="w-full bg-slate-50 border border-slate-200 rounded-lg pl-9 pr-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-100"
                    value={searchTerm}
                    onChange={e => setSearchTerm(e.target.value)}
                />
            </div>
        </div>

        {/* Contenedor de la Tabla */}
        <div className="bg-white rounded-b-2xl shadow-sm border border-slate-200 overflow-hidden">
            <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                    <thead className="bg-slate-50 border-b border-slate-200">
                        <tr>
                            <th className="px-6 py-4 font-bold text-slate-500 uppercase text-xs tracking-wider">ID</th>
                            <th className="px-6 py-4 font-bold text-slate-500 uppercase text-xs tracking-wider">Obra / Autor</th>
                            <th className="px-6 py-4 font-bold text-slate-500 uppercase text-xs tracking-wider">Género</th>
                            <th className="px-6 py-4 font-bold text-slate-500 uppercase text-xs tracking-wider text-right">Precio</th>
                            <th className="px-6 py-4 font-bold text-slate-500 uppercase text-xs tracking-wider text-center">Acciones</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                        {filteredLibros.length > 0 ? filteredLibros.map((l) => (
                            <tr key={l.ID_LIBRO} className="hover:bg-slate-50 transition-colors group">
                                <td className="px-6 py-4">
                                    <span className="font-mono text-slate-400 font-bold">#{l.ID_LIBRO}</span>
                                </td>
                                <td className="px-6 py-4">
                                    <div className="font-bold text-slate-800 text-base">{l.TITULO}</div>
                                    <div className="text-slate-500 text-xs italic">{l.AUTOR}</div>
                                </td>
                                <td className="px-6 py-4">
                                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-600 border border-slate-200 uppercase tracking-wide">
                                        <Tag size={10} /> {l.GENERO}
                                    </span>
                                </td>
                                <td className="px-6 py-4 text-right">
                                    <span className="font-bold text-indigo-700 text-base font-mono bg-indigo-50 px-2 py-1 rounded">
                                        ${l.PRECIO}
                                    </span>
                                </td>
                                <td className="px-6 py-4">
                                    <div className="flex items-center justify-center gap-2 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity">
                                        <button 
                                            onClick={() => handleUpdatePrecio(l.ID_LIBRO, l.PRECIO, l.TITULO)}
                                            className="p-2 text-slate-500 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg transition-colors tooltip"
                                            title="Editar Precio">
                                            <Edit3 size={18} />
                                        </button>
                                        <button 
                                            onClick={() => verHistorial(l.ID_LIBRO, l.TITULO)}
                                            className="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                                            title="Ver Historial">
                                            <TrendingUp size={18} />
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        )) : (
                            <tr>
                                <td colSpan="5" className="px-6 py-12 text-center text-slate-400">
                                    {libros.length === 0 ? "No hay libros registrados aún." : "No se encontraron libros con esa búsqueda."}
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
      </div>

      {/* MODAL HISTORIAL (Mismo diseño) */}
      {modalOpen && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-fadeIn">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden flex flex-col max-h-[80vh]">
            <div className="bg-slate-50 p-5 border-b border-slate-100 flex justify-between items-center">
              <div>
                  <h3 className="font-bold text-lg text-slate-800">Historial de Precios</h3>
                  <p className="text-sm text-slate-500 truncate max-w-[250px]">{bookSelectedName}</p>
              </div>
              <button onClick={() => setModalOpen(false)} className="w-8 h-8 rounded-full bg-white hover:bg-slate-200 text-slate-500 flex items-center justify-center transition-colors">✕</button>
            </div>
            
            <div className="overflow-y-auto p-0">
              <table className="w-full text-left border-collapse">
                  <thead className="bg-slate-50 text-xs text-slate-500 uppercase font-semibold sticky top-0">
                      <tr>
                          <th className="px-6 py-3 border-b border-slate-200">Precio</th>
                          <th className="px-6 py-3 border-b border-slate-200">Vigencia</th>
                          <th className="px-6 py-3 border-b border-slate-200 text-center">Estado</th>
                      </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                      {historial.map((h, i) => (
                        <tr key={i} className="hover:bg-slate-50 transition-colors">
                          <td className="px-6 py-4">
                            <span className="font-bold text-slate-700">${h.PRECIO}</span>
                          </td>
                          <td className="px-6 py-4">
                            <div className="flex flex-col">
                                <span className="text-sm text-slate-600">{new Date(h.FECHA_INICIO).toLocaleDateString()}</span>
                                <span className="text-[10px] text-slate-400">Inicio</span>
                            </div>
                          </td>
                          <td className="px-6 py-4 text-center">
                            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold ${
                                h.ESTADO_PRECIO === 'VIGENTE' 
                                ? 'bg-emerald-100 text-emerald-700 border border-emerald-200' 
                                : 'bg-slate-100 text-slate-500 border border-slate-200'
                            }`}>
                              {h.ESTADO_PRECIO}
                            </span>
                          </td>
                        </tr>
                      ))}
                  </tbody>
              </table>
              {historial.length === 0 && (
                  <div className="p-8 text-center text-slate-400">Sin historial registrado.</div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}