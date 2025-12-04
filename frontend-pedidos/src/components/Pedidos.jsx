import { useState, useEffect } from 'react';
import api from '../api';
import { PlusCircle, ShoppingCart, Truck, Eye, AlertCircle, X, Save, Search, User } from 'lucide-react';

// Lista exacta de estados según tu BD
const ESTADOS_POSIBLES = [
  'Pendiente', 
  'Pagado', 
  'En Preparación', 
  'Enviado', 
  'Entregado', 
  'Cancelado'
];

export default function Pedidos() {
  const [pedidos, setPedidos] = useState([]);
  const [libros, setLibros] = useState([]);
  
  // --- NUEVO: ESTADO PARA CLIENTES ---
  const [clientes, setClientes] = useState([]);
  const [busquedaCliente, setBusquedaCliente] = useState(''); // Para filtrar el select
  const [idCliente, setIdCliente] = useState('');

  const [detalle, setDetalle] = useState({ id_pedido: '', id_libro: '', cantidad: 1 });
  
  // --- ESTADOS PARA MODAL DETALLE (CURSOR) ---
  const [modalDetalleOpen, setModalDetalleOpen] = useState(false);
  const [pedidoSeleccionado, setPedidoSeleccionado] = useState([]);
  const [loadingDetalle, setLoadingDetalle] = useState(false);

  // --- ESTADOS PARA MODAL CAMBIO DE ESTADO ---
  const [modalEstadoOpen, setModalEstadoOpen] = useState(false);
  const [estadoForm, setEstadoForm] = useState({ id_pedido: '', estado_actual: '', nuevo_estado: '' }); // Eliminado observaciones
  const [loadingEstado, setLoadingEstado] = useState(false);

  const fetchPedidos = () => api.get('/pedidos').then(res => setPedidos(res.data));
  const fetchLibros = () => api.get('/libros').then(res => setLibros(res.data));
  // Traemos los clientes para el buscador
  const fetchClientes = () => api.get('/clientes').then(res => setClientes(res.data));

  useEffect(() => { 
    fetchPedidos(); 
    fetchLibros(); 
    fetchClientes();
  }, []);

  const crearPedido = async () => {
    if(!idCliente) return alert("Por favor, seleccione un cliente de la lista.");
    try {
      const res = await api.post('/pedidos', { id_cliente: idCliente });
      alert(`✅ Pedido #${res.data.id_pedido} creado exitosamente.`);
      setDetalle({ ...detalle, id_pedido: res.data.id_pedido });
      
      // Resetear selección
      setIdCliente('');
      setBusquedaCliente('');
      fetchPedidos();
    } catch (err) { alert('Error: ' + err.message); }
  };

  const agregarDetalle = async () => {
    if(!detalle.id_pedido || !detalle.id_libro) return alert("Complete los datos");
    try {
      await api.post('/pedidos/detalle', detalle);
      fetchPedidos();
    } catch (err) { alert('Error: ' + (err.response?.data?.error || err.message)); }
  };

  // --- LOGICA MODAL ESTADO ---
  const abrirModalEstado = (pedido) => {
    setEstadoForm({
        id_pedido: pedido.ID_PEDIDO,
        estado_actual: pedido.NOMBRE_ESTADO,
        nuevo_estado: pedido.NOMBRE_ESTADO, 
    });
    setModalEstadoOpen(true);
  };

  const guardarNuevoEstado = async (e) => {
    e.preventDefault();
    setLoadingEstado(true);
    try {
      // Ya no enviamos observaciones
      await api.put('/pedidos/estado', { 
          id_pedido: estadoForm.id_pedido, 
          nuevo_estado: estadoForm.nuevo_estado 
      });
      alert('✅ Estado actualizado correctamente');
      setModalEstadoOpen(false);
      fetchPedidos();
    } catch (err) { 
        alert('Error: ' + (err.response?.data?.error || err.message)); 
    } finally {
        setLoadingEstado(false);
    }
  };

  const verDetallePedido = async (idPedido) => {
    setLoadingDetalle(true);
    setModalDetalleOpen(true);
    setPedidoSeleccionado([]);
    try {
        const res = await api.get(`/pedidos/${idPedido}`);
        setPedidoSeleccionado(res.data);
    } catch (err) {
        if(err.response?.status !== 404) console.error(err);
    } finally {
        setLoadingDetalle(false);
    }
  };

  const getStatusColor = (status) => {
    switch(status) {
      case 'Pendiente': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'Pagado': return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'En Preparación': return 'bg-orange-100 text-orange-800 border-orange-200'; // Nuevo color
      case 'Enviado': return 'bg-purple-100 text-purple-800 border-purple-200';
      case 'Entregado': return 'bg-green-100 text-green-800 border-green-200';
      case 'Cancelado': return 'bg-red-100 text-red-800 border-red-200';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  // Filtrado de clientes para el buscador
  const clientesFiltrados = clientes.filter(c => 
    c.NOMBRE.toLowerCase().includes(busquedaCliente.toLowerCase())
  );

  return (
    <div className="grid grid-cols-1 xl:grid-cols-3 gap-8 p-6">
      
      {/* SECCIÓN IZQUIERDA: Formularios */}
      <div className="xl:col-span-1 space-y-6">
        
        {/* 1. Crear Pedido (CORREGIDO: SELECCIÓN DE CLIENTE) */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
          <h3 className="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2">
            <PlusCircle className="text-indigo-600" /> Nuevo Pedido
          </h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-600 mb-1">Buscar Cliente</label>
              
              {/* Buscador de texto para filtrar la lista */}
              <div className="relative mb-2">
                <Search size={16} className="absolute left-3 top-2.5 text-slate-400" />
                <input 
                  className="w-full border border-slate-300 rounded-lg pl-9 pr-3 py-2 text-sm outline-none focus:ring-2 focus:ring-indigo-500"
                  placeholder="Escribe para filtrar..."
                  value={busquedaCliente}
                  onChange={e => setBusquedaCliente(e.target.value)}
                />
              </div>

              {/* Select con los resultados filtrados */}
              <select 
                className="w-full border border-slate-300 rounded-lg p-2.5 outline-none bg-slate-50 focus:bg-white transition-colors"
                value={idCliente} 
                onChange={e => setIdCliente(e.target.value)}
                size={clientesFiltrados.length > 5 ? 5 : 0} // Si hay muchos, se convierte en lista
              >
                <option value="">-- Seleccionar Cliente --</option>
                {clientesFiltrados.map(c => (
                  <option key={c.ID_CLIENTE} value={c.ID_CLIENTE}>
                    {c.NOMBRE}
                  </option>
                ))}
              </select>
              {clientesFiltrados.length === 0 && (
                <p className="text-xs text-red-500 mt-1">No se encontraron clientes.</p>
              )}
            </div>

            <button 
                onClick={crearPedido} 
                disabled={!idCliente}
                className="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-slate-300 disabled:cursor-not-allowed text-white py-2.5 rounded-lg font-bold transition-colors shadow-md">
                Iniciar Pedido
            </button>
          </div>
        </div>

        {/* 2. Agregar Items */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 relative overflow-hidden">
          <div className="absolute top-0 right-0 p-4 opacity-5 pointer-events-none">
            <ShoppingCart size={100} />
          </div>
          <h3 className="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2">
            <ShoppingCart className="text-emerald-600" /> Agregar Items
          </h3>
          <div className="space-y-4 relative z-10">
            <div>
              <label className="block text-sm font-medium text-slate-600 mb-1">ID Pedido</label>
              <input className="w-full border border-slate-300 rounded-lg p-2.5 bg-slate-50 font-mono text-sm" 
                placeholder="ID del pedido creado" type="number"
                value={detalle.id_pedido} onChange={e => setDetalle({...detalle, id_pedido: e.target.value})} />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-600 mb-1">Libro</label>
              <select className="w-full border border-slate-300 rounded-lg p-2.5 outline-none bg-white" 
                value={detalle.id_libro} onChange={e => setDetalle({...detalle, id_libro: e.target.value})}>
                <option value="">Seleccionar del catálogo...</option>
                {libros.map(l => <option key={l.ID_LIBRO} value={l.ID_LIBRO}>{l.TITULO} - {l.AUTOR} (${l.PRECIO})</option>)}
              </select>
            </div>
            <div className="flex gap-4 items-end">
              <div className="w-1/3">
                <label className="block text-sm font-medium text-slate-600 mb-1">Cant.</label>
                <input className="w-full border border-slate-300 rounded-lg p-2.5" 
                  type="number" min="1"
                  value={detalle.cantidad} onChange={e => setDetalle({...detalle, cantidad: e.target.value})} />
              </div>
              <button onClick={agregarDetalle} className="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-medium transition-colors h-[42px]">
                Agregar
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* SECCIÓN DERECHA: Lista de Pedidos */}
      <div className="xl:col-span-2">
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center bg-slate-50">
            <h3 className="font-bold text-slate-700">Pedidos Recientes</h3>
            <span className="text-xs font-medium bg-white border border-slate-200 px-2 py-1 rounded text-slate-500">
              {pedidos.length} Registros
            </span>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm text-left">
              <thead className="text-xs text-slate-500 uppercase bg-slate-50">
                <tr>
                  <th className="px-6 py-3">Info</th>
                  <th className="px-6 py-3">Cliente</th>
                  <th className="px-6 py-3">Estado</th>
                  <th className="px-6 py-3 text-right">Monto</th>
                  <th className="px-6 py-3 text-center">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {pedidos.map(p => (
                  <tr key={p.ID_PEDIDO} className="hover:bg-slate-50 transition-colors">
                    <td className="px-6 py-4">
                        <span className="font-mono text-indigo-600 font-bold">#{p.ID_PEDIDO}</span>
                        <div className="text-[10px] text-slate-400 mt-1">{new Date(p.FECHA).toLocaleDateString()}</div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="font-semibold text-slate-800">{p.NOMBRE_COMPLETO}</div>
                      <div className="text-xs text-slate-500">{p.CIUDAD}</div>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold border uppercase tracking-wide ${getStatusColor(p.NOMBRE_ESTADO)}`}>
                        {p.NOMBRE_ESTADO}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right font-mono text-slate-700">
                      ${(p.TOTAL || 0).toLocaleString()}
                    </td>
                    <td className="px-6 py-4 text-center">
                        <div className="flex justify-center gap-2">
                            <button onClick={() => abrirModalEstado(p)} 
                                className="p-1.5 text-slate-500 hover:text-indigo-600 hover:bg-indigo-50 rounded transition-colors" title="Cambiar Estado">
                                <Truck size={16} />
                            </button>
                            <button onClick={() => verDetallePedido(p.ID_PEDIDO)} 
                                className="p-1.5 text-slate-500 hover:text-emerald-600 hover:bg-emerald-50 rounded transition-colors" title="Ver Detalle Completo">
                                <Eye size={16} />
                            </button>
                        </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* --- MODAL CAMBIAR ESTADO (CORREGIDO: SIN OBSERVACIONES) --- */}
      {modalEstadoOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-fadeIn">
            <div className="bg-white rounded-xl shadow-2xl w-full max-w-sm overflow-hidden">
                <div className="bg-indigo-600 px-6 py-4 flex justify-between items-center">
                    <h3 className="text-white font-bold text-lg flex items-center gap-2">
                        <Truck size={20} /> Actualizar Estado
                    </h3>
                    <button onClick={() => setModalEstadoOpen(false)} className="text-white/80 hover:text-white transition-colors">
                        <X size={24} />
                    </button>
                </div>
                
                <form onSubmit={guardarNuevoEstado} className="p-6 space-y-4">
                    <div className="bg-slate-50 p-3 rounded-lg border border-slate-100 text-sm">
                        <span className="text-slate-500 font-medium">Pedido: </span>
                        <span className="font-mono font-bold text-indigo-700">#{estadoForm.id_pedido}</span>
                        <div className="mt-1">
                             <span className="text-slate-500 font-medium">Estado Actual: </span>
                             <span className="font-bold text-slate-700">{estadoForm.estado_actual}</span>
                        </div>
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-slate-700 mb-1">Seleccionar Nuevo Estado</label>
                        <select required className="w-full border border-slate-300 rounded-lg p-2.5 outline-none focus:ring-2 focus:ring-indigo-500"
                            value={estadoForm.nuevo_estado}
                            onChange={e => setEstadoForm({...estadoForm, nuevo_estado: e.target.value})}>
                            {ESTADOS_POSIBLES.map(est => (
                                <option key={est} value={est}>{est}</option>
                            ))}
                        </select>
                    </div>

                    {/* SECCIÓN OBSERVACIONES ELIMINADA */}

                    <div className="flex gap-3 justify-end pt-2">
                        <button type="button" onClick={() => setModalEstadoOpen(false)} 
                            className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg font-medium text-sm">
                            Cancelar
                        </button>
                        <button type="submit" disabled={loadingEstado} 
                            className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium text-sm flex items-center gap-2 shadow-sm">
                            {loadingEstado ? 'Guardando...' : <><Save size={16}/> Guardar</>}
                        </button>
                    </div>
                </form>
            </div>
        </div>
      )}

      {/* --- MODAL DETALLE (SIN CAMBIOS) --- */}
      {modalDetalleOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-fadeIn">
            <div className="bg-white rounded-xl shadow-2xl w-full max-w-2xl overflow-hidden flex flex-col max-h-[90vh]">
                <div className="bg-slate-900 text-white p-4 flex justify-between items-center shrink-0">
                    <h3 className="font-bold text-lg flex items-center gap-2">
                        <ShoppingCart size={20} className="text-emerald-400"/> Detalle del Pedido
                    </h3>
                    <button onClick={() => setModalDetalleOpen(false)} className="text-slate-400 hover:text-white transition-colors">✕</button>
                </div>
                
                <div className="p-6 overflow-y-auto">
                    {loadingDetalle ? (
                        <div className="text-center py-10 text-slate-500">Cargando información...</div>
                    ) : pedidoSeleccionado.length > 0 ? (
                        <>
                            <div className="grid grid-cols-2 gap-4 mb-6 bg-slate-50 p-4 rounded-lg border border-slate-100">
                                <div>
                                    <p className="text-xs text-slate-500 uppercase font-bold">Cliente</p>
                                    <p className="text-slate-800 font-medium">{pedidoSeleccionado[0].CLIENTE}</p>
                                    <p className="text-sm text-slate-500">{pedidoSeleccionado[0].CORREO_ELECTRONICO}</p>
                                </div>
                                <div className="text-right">
                                    <p className="text-xs text-slate-500 uppercase font-bold">Entrega</p>
                                    <p className="text-slate-800 text-sm">{pedidoSeleccionado[0].DIRECCION_ENTREGA}</p>
                                    <p className="text-indigo-600 font-bold">{pedidoSeleccionado[0].CIUDAD}</p>
                                </div>
                            </div>
                            <table className="w-full text-sm mb-6">
                                <thead className="text-xs text-slate-400 uppercase bg-white border-b">
                                    <tr>
                                        <th className="py-2 text-left">Libro</th>
                                        <th className="py-2 text-center">Cant.</th>
                                        <th className="py-2 text-right">P. Unit</th>
                                        <th className="py-2 text-right">Subtotal</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {pedidoSeleccionado.map((item, idx) => (
                                        <tr key={idx} className="border-b border-slate-50 last:border-0">
                                            <td className="py-3">
                                                <div className="font-medium text-slate-700">{item.LIBRO_TITULO}</div>
                                                <div className="text-xs text-slate-500">{item.LIBRO_AUTOR}</div>
                                            </td>
                                            <td className="py-3 text-center">{item.CANTIDAD}</td>
                                            <td className="py-3 text-right">${item.PRECIO_UNITARIO}</td>
                                            <td className="py-3 text-right font-medium">${item.SUBTOTAL_ITEM}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                            <div className="flex justify-end border-t border-slate-200 pt-4">
                                <div className="text-right">
                                    <p className="text-sm text-slate-500">Monto Total</p>
                                    <p className="text-3xl font-bold text-indigo-600">${pedidoSeleccionado[0].MONTO_TOTAL_PEDIDO}</p>
                                </div>
                            </div>
                        </>
                    ) : (
                        <div className="text-center py-10 flex flex-col items-center text-slate-400">
                            <AlertCircle size={48} className="mb-2 opacity-50"/>
                            <p>No se encontraron detalles para este pedido.</p>
                        </div>
                    )}
                </div>
            </div>
        </div>
      )}

      <style>{`@keyframes fadeIn { from { opacity: 0; transform: scale(0.95); } to { opacity: 1; transform: scale(1); } } .animate-fadeIn { animation: fadeIn 0.2s ease-out; }`}</style>
    </div>
  );
}