import { useState, useEffect } from 'react';
import { Shield, Save } from 'lucide-react';
import api from '../services/api';
import { useToast } from '../components/Toast';

export default function Roles() {
  const [roles, setRoles] = useState([]);
  const [modulos, setModulos] = useState([]);
  const [permisos, setPermisos] = useState([]);
  const [selectedRol, setSelectedRol] = useState(null);
  const [loading, setLoading] = useState(true);
  const toast = useToast();

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [rRes, mRes] = await Promise.all([api.get('/rol'), api.get('/modulo')]);
      setRoles(rRes.data);
      setModulos(mRes.data);
      if (rRes.data.length > 0) selectRol(rRes.data[0]);
    } catch { toast.error('Error al cargar roles'); }
    finally { setLoading(false); }
  };

  const selectRol = async (rol) => {
    setSelectedRol(rol);
    try {
      const res = await api.get(`/permiso/rol/${rol.id}`);
      setPermisos(res.data);
    } catch { setPermisos([]); }
  };

  const getPermiso = (moduloId) => {
    return permisos.find(p => p.moduloId === moduloId) || { leer: false, crear: false, editar: false, eliminar: false };
  };

  const togglePermiso = (moduloId, accion) => {
    setPermisos(prev => {
      const existing = prev.find(p => p.moduloId === moduloId);
      if (existing) {
        return prev.map(p => p.moduloId === moduloId ? {...p, [accion]: !p[accion]} : p);
      }
      return [...prev, { moduloId, rolId: selectedRol.id, leer: false, crear: false, editar: false, eliminar: false, [accion]: true }];
    });
  };

  const handleSave = async () => {
    if (!selectedRol) return;
    try {
      await api.put(`/permiso/rol/${selectedRol.id}`, permisos.map(p => ({
        moduloId: p.moduloId,
        rolId: selectedRol.id,
        leer: p.leer || false,
        crear: p.crear || false,
        editar: p.editar || false,
        eliminar: p.eliminar || false,
      })));
      toast.success('Permisos guardados exitosamente');
    } catch (err) { toast.error(err.response?.data?.message || 'Error al guardar permisos'); }
  };

  if (loading) return <div className="loading-screen"><div className="spinner"/><span>Cargando...</span></div>;

  return (
    <div style={{ animation: 'slideInLeft 0.3s ease' }}>
      <div className="page-header">
        <h1>Roles y Permisos</h1>
        <button className="btn btn-fire" onClick={handleSave} disabled={!selectedRol}>
          <Save size={16}/> Guardar Cambios
        </button>
      </div>

      {/* Role Tabs */}
      <div className="flex gap-sm mb-3" style={{ flexWrap: 'wrap' }}>
        {roles.map(r => (
          <button key={r.id}
            className={`btn ${selectedRol?.id === r.id ? 'btn-fire' : 'btn-secondary'}`}
            onClick={() => selectRol(r)}>
            <Shield size={14}/> {r.nombre}
          </button>
        ))}
      </div>

      {/* Permission Matrix */}
      {selectedRol && (
        <div className="table-container">
          <table>
            <thead>
              <tr>
                <th>Módulo</th>
                <th style={{textAlign:'center'}}>Leer</th>
                <th style={{textAlign:'center'}}>Crear</th>
                <th style={{textAlign:'center'}}>Editar</th>
                <th style={{textAlign:'center'}}>Eliminar</th>
              </tr>
            </thead>
            <tbody>
              {modulos.map(m => {
                const p = getPermiso(m.id);
                return (
                  <tr key={m.id}>
                    <td><strong>{m.nombre}</strong></td>
                    {['leer', 'crear', 'editar', 'eliminar'].map(acc => (
                      <td key={acc} style={{textAlign:'center'}}>
                        <label style={{cursor:'pointer',display:'inline-flex',alignItems:'center',justifyContent:'center',width:36,height:36,borderRadius:'var(--radius-sm)',
                          background: p[acc] ? 'var(--gradient-fire-subtle)' : 'var(--bg-input)',
                          border: `1px solid ${p[acc] ? 'rgba(255,59,48,0.3)' : 'var(--border-color)'}`,
                          transition: 'all 0.15s ease'}}>
                          <input type="checkbox" checked={p[acc] || false}
                            onChange={() => togglePermiso(m.id, acc)}
                            style={{width:16,height:16,accentColor:'#ff3b30'}}/>
                        </label>
                      </td>
                    ))}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
