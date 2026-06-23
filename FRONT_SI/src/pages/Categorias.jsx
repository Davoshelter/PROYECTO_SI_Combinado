import { useState, useEffect } from 'react';
import { Plus, Search, Edit2, Trash2 } from 'lucide-react';
import api from '../services/api';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../components/Toast';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';

export default function Categorias() {
  const [items, setItems] = useState([]);
  const [busqueda, setBusqueda] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [selected, setSelected] = useState(null);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState({ nombre: '', descripcion: '' });
  const { tienePermiso } = useAuth();
  const toast = useToast();

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    try { setLoading(true); const res = await api.get('/categoria'); setItems(res.data); }
    catch { toast.error('Error al cargar categorías'); }
    finally { setLoading(false); }
  };

  const filtered = items.filter(c => c.nombre?.toLowerCase().includes(busqueda.toLowerCase()));

  const openCreate = () => { setSelected(null); setForm({ nombre: '', descripcion: '' }); setShowModal(true); };
  const openEdit = (item) => { setSelected(item); setForm({ nombre: item.nombre || '', descripcion: item.descripcion || '' }); setShowModal(true); };

  const handleSave = async () => {
    if (!form.nombre.trim()) { toast.error('El nombre es requerido'); return; }
    try {
      if (selected) { await api.put(`/categoria/${selected.id}`, form); toast.success('Categoría actualizada'); }
      else { await api.post('/categoria', form); toast.success('Categoría creada'); }
      setShowModal(false); loadData();
    } catch (err) { toast.error(err.response?.data?.message || 'Error al guardar'); }
  };

  const handleDelete = async () => {
    try { await api.delete(`/categoria/${selected.id}`); toast.success('Categoría eliminada'); setShowConfirm(false); loadData(); }
    catch (err) { toast.error(err.response?.data?.message || 'Error al eliminar'); }
  };

  if (loading) return <div className="loading-screen"><div className="spinner"/><span>Cargando...</span></div>;

  return (
    <div style={{ animation: 'slideInLeft 0.3s ease' }}>
      <div className="page-header">
        <h1>Categorías</h1>
        <div className="flex gap-sm">
          <div className="search-bar">
            <Search size={16} className="search-icon" />
            <input className="form-control" placeholder="Buscar..." value={busqueda}
              onChange={(e) => setBusqueda(e.target.value)} />
          </div>
          {tienePermiso('Categorias', 'Crear') && (
            <button className="btn btn-fire" onClick={openCreate}><Plus size={16}/> Nueva</button>
          )}
        </div>
      </div>
      <div className="table-container">
        <table>
          <thead><tr><th>Nombre</th><th>Descripción</th><th>Acciones</th></tr></thead>
          <tbody>
            {filtered.map(c => (
              <tr key={c.id}>
                <td><strong>{c.nombre}</strong></td>
                <td className="text-muted">{c.descripcion || '—'}</td>
                <td>
                  <div className="flex gap-sm">
                    {tienePermiso('Categorias', 'Editar') && <button className="btn btn-ghost btn-sm" onClick={() => openEdit(c)}><Edit2 size={14}/></button>}
                    {tienePermiso('Categorias', 'Eliminar') && <button className="btn btn-ghost btn-sm" style={{color:'var(--danger)'}} onClick={() => {setSelected(c); setShowConfirm(true);}}><Trash2 size={14}/></button>}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <Modal isOpen={showModal} onClose={() => setShowModal(false)} title={selected ? 'Editar Categoría' : 'Nueva Categoría'}>
        <div className="form-group"><label>Nombre *</label>
          <input className="form-control" value={form.nombre} onChange={e => setForm({...form, nombre: e.target.value})} /></div>
        <div className="form-group"><label>Descripción</label>
          <textarea className="form-control" rows={3} value={form.descripcion} onChange={e => setForm({...form, descripcion: e.target.value})} /></div>
        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={() => setShowModal(false)}>Cancelar</button>
          <button className="btn btn-fire" onClick={handleSave}>{selected ? 'Actualizar' : 'Crear'}</button>
        </div>
      </Modal>
      <ConfirmDialog isOpen={showConfirm} onClose={() => setShowConfirm(false)} onConfirm={handleDelete}
        title="¿Eliminar categoría?" message={`Se eliminará "${selected?.nombre}".`} />
    </div>
  );
}
