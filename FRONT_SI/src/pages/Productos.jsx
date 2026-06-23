import { useState, useEffect } from 'react';
import { Plus, Search, Edit2, Trash2, Package, AlertTriangle } from 'lucide-react';
import api from '../services/api';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../components/Toast';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';

export default function Productos() {
  const [items, setItems] = useState([]);
  const [categorias, setCategorias] = useState([]);
  const [busqueda, setBusqueda] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [selected, setSelected] = useState(null);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState({
    nombre: '', descripcion: '', codigoBarras: '', precioCompraUSD: 0,
    precioVentaUSD: 0, stock: 0, stockMinimo: 5, categoriaId: '', activo: true,
  });
  const { tienePermiso } = useAuth();
  const toast = useToast();

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [pRes, cRes] = await Promise.all([api.get('/producto'), api.get('/categoria')]);
      setItems(pRes.data);
      setCategorias(cRes.data);
    } catch { toast.error('Error al cargar productos'); }
    finally { setLoading(false); }
  };

  const filtered = items.filter(p =>
    p.nombre?.toLowerCase().includes(busqueda.toLowerCase()) ||
    p.codigoBarras?.toLowerCase().includes(busqueda.toLowerCase())
  );

  const openCreate = () => {
    setSelected(null);
    setForm({ nombre: '', descripcion: '', codigoBarras: '', precioCompraUSD: 0,
      precioVentaUSD: 0, stock: 0, stockMinimo: 5, categoriaId: categorias[0]?.id || '', activo: true });
    setShowModal(true);
  };

  const openEdit = (item) => {
    setSelected(item);
    setForm({
      nombre: item.nombre || '', descripcion: item.descripcion || '',
      codigoBarras: item.codigoBarras || '', precioCompraUSD: item.precioCompraUSD || 0,
      precioVentaUSD: item.precioVentaUSD || 0, stock: item.stock || 0,
      stockMinimo: item.stockMinimo || 5, categoriaId: item.categoriaId || '',
      activo: item.activo !== false,
    });
    setShowModal(true);
  };

  const handleSave = async () => {
    if (!form.nombre.trim()) { toast.error('El nombre es requerido'); return; }
    try {
      const body = { ...form, categoriaId: form.categoriaId ? Number(form.categoriaId) : null,
        precioCompraUSD: Number(form.precioCompraUSD), precioVentaUSD: Number(form.precioVentaUSD),
        stock: Number(form.stock), stockMinimo: Number(form.stockMinimo) };
      if (selected) {
        await api.put(`/producto/${selected.id}`, body);
        toast.success('Producto actualizado');
      } else {
        await api.post('/producto', body);
        toast.success('Producto creado');
      }
      setShowModal(false);
      loadData();
    } catch (err) { toast.error(err.response?.data?.message || 'Error al guardar'); }
  };

  const handleDelete = async () => {
    try {
      await api.delete(`/producto/${selected.id}`);
      toast.success('Producto eliminado');
      setShowConfirm(false);
      setSelected(null);
      loadData();
    } catch (err) { toast.error(err.response?.data?.message || 'Error al eliminar'); }
  };

  if (loading) return <div className="loading-screen"><div className="spinner"/><span>Cargando...</span></div>;

  return (
    <div style={{ animation: 'slideInLeft 0.3s ease' }}>
      <div className="page-header">
        <h1>Productos</h1>
        <div className="flex gap-sm">
          <div className="search-bar">
            <Search size={16} className="search-icon" />
            <input className="form-control" placeholder="Buscar..." value={busqueda}
              onChange={(e) => setBusqueda(e.target.value)} />
          </div>
          {tienePermiso('Productos', 'Crear') && (
            <button className="btn btn-fire" onClick={openCreate}><Plus size={16}/> Nuevo</button>
          )}
        </div>
      </div>

      <div className="table-container">
        <table>
          <thead>
            <tr>
              <th>Nombre</th><th>Código</th><th>Categoría</th>
              <th>P. Compra</th><th>P. Venta</th><th>Stock</th><th>Estado</th><th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(p => (
              <tr key={p.id}>
                <td><strong>{p.nombre}</strong></td>
                <td className="text-muted">{p.codigoBarras || '—'}</td>
                <td>{p.categoriaNombre || '—'}</td>
                <td>${p.precioCompraUSD?.toFixed(2)}</td>
                <td style={{ fontWeight: 600, color: 'var(--yellow-400)' }}>${p.precioVentaUSD?.toFixed(2)}</td>
                <td>
                  <span className={`badge ${p.stock <= (p.stockMinimo||5) ? (p.stock === 0 ? 'badge-danger' : 'badge-warning') : 'badge-success'}`}>
                    {p.stock}
                  </span>
                </td>
                <td><span className={`badge ${p.activo !== false ? 'badge-success' : 'badge-danger'}`}>
                  {p.activo !== false ? 'Activo' : 'Inactivo'}
                </span></td>
                <td>
                  <div className="flex gap-sm">
                    {tienePermiso('Productos', 'Editar') && (
                      <button className="btn btn-ghost btn-sm" onClick={() => openEdit(p)}><Edit2 size={14}/></button>
                    )}
                    {tienePermiso('Productos', 'Eliminar') && (
                      <button className="btn btn-ghost btn-sm" style={{color:'var(--danger)'}}
                        onClick={() => {setSelected(p); setShowConfirm(true);}}><Trash2 size={14}/></button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal CRUD */}
      <Modal isOpen={showModal} onClose={() => setShowModal(false)}
        title={selected ? 'Editar Producto' : 'Nuevo Producto'} size="lg">
        <div className="grid-2">
          <div className="form-group"><label>Nombre *</label>
            <input className="form-control" value={form.nombre}
              onChange={e => setForm({...form, nombre: e.target.value})} /></div>
          <div className="form-group"><label>Código de Barras</label>
            <input className="form-control" value={form.codigoBarras}
              onChange={e => setForm({...form, codigoBarras: e.target.value})} /></div>
        </div>
        <div className="form-group"><label>Descripción</label>
          <textarea className="form-control" rows={2} value={form.descripcion}
            onChange={e => setForm({...form, descripcion: e.target.value})} /></div>
        <div className="grid-2">
          <div className="form-group"><label>Categoría</label>
            <select className="form-control" value={form.categoriaId}
              onChange={e => setForm({...form, categoriaId: e.target.value})}>
              <option value="">Sin categoría</option>
              {categorias.map(c => <option key={c.id} value={c.id}>{c.nombre}</option>)}
            </select></div>
          <div className="form-group"><label>Estado</label>
            <select className="form-control" value={form.activo ? 'true' : 'false'}
              onChange={e => setForm({...form, activo: e.target.value === 'true'})}>
              <option value="true">Activo</option>
              <option value="false">Inactivo</option>
            </select></div>
        </div>
        <div className="grid-2">
          <div className="form-group"><label>Precio Compra (USD)</label>
            <input type="number" className="form-control" min="0" step="0.01"
              value={form.precioCompraUSD}
              onChange={e => setForm({...form, precioCompraUSD: e.target.value})} /></div>
          <div className="form-group"><label>Precio Venta (USD)</label>
            <input type="number" className="form-control" min="0" step="0.01"
              value={form.precioVentaUSD}
              onChange={e => setForm({...form, precioVentaUSD: e.target.value})} /></div>
        </div>
        <div className="grid-2">
          <div className="form-group"><label>Stock</label>
            <input type="number" className="form-control" min="0"
              value={form.stock}
              onChange={e => setForm({...form, stock: e.target.value})} /></div>
          <div className="form-group"><label>Stock Mínimo</label>
            <input type="number" className="form-control" min="0"
              value={form.stockMinimo}
              onChange={e => setForm({...form, stockMinimo: e.target.value})} /></div>
        </div>
        <div className="modal-footer">
          <button className="btn btn-secondary" onClick={() => setShowModal(false)}>Cancelar</button>
          <button className="btn btn-fire" onClick={handleSave}>
            {selected ? 'Actualizar' : 'Crear'}
          </button>
        </div>
      </Modal>

      <ConfirmDialog isOpen={showConfirm} onClose={() => setShowConfirm(false)}
        onConfirm={handleDelete} title="¿Eliminar producto?"
        message={`Se eliminará "${selected?.nombre}". Esta acción no se puede deshacer.`} />
    </div>
  );
}
