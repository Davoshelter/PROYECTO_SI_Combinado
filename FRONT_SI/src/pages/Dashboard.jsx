import { useState, useEffect } from 'react';
import {
  DollarSign,
  ShoppingCart,
  Package,
  Users,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
} from 'lucide-react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  LineElement,
  PointElement,
  ArcElement,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js';
import { Bar, Line, Doughnut } from 'react-chartjs-2';
import api from '../services/api';
import { useToast } from '../components/Toast';
import './Dashboard.css';

ChartJS.register(
  CategoryScale, LinearScale, BarElement, LineElement, PointElement,
  ArcElement, Tooltip, Legend, Filler
);

export default function Dashboard() {
  const [stats, setStats] = useState({
    ventasHoy: 0,
    totalVentas: 0,
    productosActivos: 0,
    clientesRegistrados: 0,
  });
  const [ventasSemana, setVentasSemana] = useState([]);
  const [topProductos, setTopProductos] = useState([]);
  const [stockBajo, setStockBajo] = useState([]);
  const [loading, setLoading] = useState(true);
  const toast = useToast();

  useEffect(() => {
    loadDashboard();
  }, []);

  const loadDashboard = async () => {
    try {
      setLoading(true);
      const [ventasRes, prodRes, clienteRes] = await Promise.allSettled([
        api.get('/venta'),
        api.get('/producto'),
        api.get('/cliente'),
      ]);

      const ventas = ventasRes.status === 'fulfilled' ? ventasRes.value.data : [];
      const productos = prodRes.status === 'fulfilled' ? prodRes.value.data : [];
      const clientes = clienteRes.status === 'fulfilled' ? clienteRes.value.data : [];

      // Calculate stats
      const hoy = new Date().toISOString().split('T')[0];
      const ventasHoy = ventas.filter(
        (v) => (v.fecha || v.creadoEn)?.split('T')[0] === hoy && v.estado !== 'Anulada' && v.estado !== 'cancelada'
      );
      const totalHoy = ventasHoy.reduce((s, v) => s + (v.total || v.totalUSD || 0), 0);
      const activos = productos.filter((p) => p.estado === 'activo' || p.activo !== false);
      const bajoStock = activos.filter((p) => p.stock <= (p.stockMinimo || 5));

      // Weekly sales data
      const weekData = Array(7).fill(0);
      const now = new Date();
      ventas
        .filter((v) => v.estado !== 'Anulada' && v.estado !== 'cancelada')
        .forEach((v) => {
          const d = new Date(v.fecha || v.creadoEn);
          const diffDays = Math.floor((now - d) / (1000 * 60 * 60 * 24));
          if (diffDays < 7) {
            weekData[d.getDay()] += v.total || v.totalUSD || 0;
          }
        });

      // Top products by sale count (from details — simplified by name)
      const prodCount = {};
      ventas
        .filter((v) => v.estado !== 'Anulada' && v.estado !== 'cancelada' && v.detalles)
        .forEach((v) => {
          v.detalles.forEach((d) => {
            const name = d.productoNombre || `Prod #${d.productoId}`;
            prodCount[name] = (prodCount[name] || 0) + (d.cantidad || 1);
          });
        });
      const top = Object.entries(prodCount)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5);

      setStats({
        ventasHoy: totalHoy,
        totalVentas: ventas.filter((v) => v.estado !== 'Anulada' && v.estado !== 'cancelada').length,
        productosActivos: activos.length,
        clientesRegistrados: clientes.length,
      });
      setVentasSemana(weekData);
      setTopProductos(top);
      setStockBajo(bajoStock.slice(0, 5));
    } catch (err) {
      toast.error('Error cargando dashboard');
    } finally {
      setLoading(false);
    }
  };

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false },
      tooltip: {
        backgroundColor: '#1a1a1e',
        borderColor: '#34343d',
        borderWidth: 1,
        titleColor: '#f3f4f6',
        bodyColor: '#9ca3af',
        cornerRadius: 8,
        padding: 12,
      },
    },
    scales: {
      x: {
        grid: { color: 'rgba(52,52,61,0.3)' },
        ticks: { color: '#9ca3af', font: { size: 11 } },
      },
      y: {
        grid: { color: 'rgba(52,52,61,0.3)' },
        ticks: { color: '#9ca3af', font: { size: 11 } },
      },
    },
  };

  const weekChartData = {
    labels: ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'],
    datasets: [
      {
        label: 'Ventas USD',
        data: ventasSemana,
        backgroundColor: (ctx) => {
          const gradient = ctx.chart.ctx.createLinearGradient(0, 0, 0, 300);
          gradient.addColorStop(0, 'rgba(255, 59, 48, 0.6)');
          gradient.addColorStop(1, 'rgba(244, 180, 0, 0.1)');
          return gradient;
        },
        borderColor: '#ff3b30',
        borderWidth: 2,
        borderRadius: 6,
        barThickness: 28,
      },
    ],
  };

  const donutData = {
    labels: topProductos.map((t) => t[0]),
    datasets: [
      {
        data: topProductos.map((t) => t[1]),
        backgroundColor: ['#ff3b30', '#f4b400', '#ff6b35', '#ffca28', '#db4437'],
        borderColor: '#1a1a1e',
        borderWidth: 3,
      },
    ],
  };

  if (loading) {
    return (
      <div className="loading-screen">
        <div className="spinner" />
        <span>Cargando dashboard...</span>
      </div>
    );
  }

  return (
    <div className="dashboard-page">
      <div className="page-header">
        <h1>Dashboard</h1>
      </div>

      {/* Metric Cards */}
      <div className="grid-4 mb-3">
        <div className="metric-card">
          <div className="metric-icon">
            <DollarSign size={24} />
          </div>
          <div className="metric-info">
            <h3>Ventas Hoy</h3>
            <div className="metric-value">${stats.ventasHoy.toFixed(2)}</div>
          </div>
        </div>
        <div className="metric-card">
          <div className="metric-icon" style={{ background: 'rgba(244,180,0,0.12)', color: '#f4b400' }}>
            <ShoppingCart size={24} />
          </div>
          <div className="metric-info">
            <h3>Total Facturas</h3>
            <div className="metric-value">{stats.totalVentas}</div>
          </div>
        </div>
        <div className="metric-card">
          <div className="metric-icon" style={{ background: 'rgba(34,197,94,0.12)', color: '#22c55e' }}>
            <Package size={24} />
          </div>
          <div className="metric-info">
            <h3>Productos</h3>
            <div className="metric-value">{stats.productosActivos}</div>
          </div>
        </div>
        <div className="metric-card">
          <div className="metric-icon" style={{ background: 'rgba(59,130,246,0.12)', color: '#3b82f6' }}>
            <Users size={24} />
          </div>
          <div className="metric-info">
            <h3>Clientes</h3>
            <div className="metric-value">{stats.clientesRegistrados}</div>
          </div>
        </div>
      </div>

      {/* Charts Row */}
      <div className="dashboard-charts">
        <div className="card chart-card">
          <h3 className="chart-title">
            <TrendingUp size={18} /> Ventas de la Semana (USD)
          </h3>
          <div className="chart-wrapper">
            <Bar data={weekChartData} options={chartOptions} />
          </div>
        </div>

        <div className="card chart-card chart-card-sm">
          <h3 className="chart-title">
            <Package size={18} /> Top Productos
          </h3>
          <div className="chart-wrapper donut-wrapper">
            {topProductos.length > 0 ? (
              <Doughnut
                data={donutData}
                options={{
                  responsive: true,
                  maintainAspectRatio: false,
                  plugins: {
                    legend: {
                      position: 'bottom',
                      labels: { color: '#9ca3af', font: { size: 11 }, padding: 12 },
                    },
                  },
                  cutout: '65%',
                }}
              />
            ) : (
              <p className="text-muted text-sm" style={{ textAlign: 'center', paddingTop: 40 }}>
                Sin datos de ventas
              </p>
            )}
          </div>
        </div>
      </div>

      {/* Low Stock Alerts */}
      {stockBajo.length > 0 && (
        <div className="card card-fire" style={{ marginTop: 24 }}>
          <h3 className="chart-title" style={{ color: 'var(--yellow-400)' }}>
            <AlertTriangle size={18} /> Alertas de Stock Bajo
          </h3>
          <div className="table-container" style={{ marginTop: 12 }}>
            <table>
              <thead>
                <tr>
                  <th>Producto</th>
                  <th>Stock Actual</th>
                  <th>Stock Mínimo</th>
                  <th>Estado</th>
                </tr>
              </thead>
              <tbody>
                {stockBajo.map((p) => (
                  <tr key={p.id}>
                    <td>{p.nombre}</td>
                    <td>{p.stock}</td>
                    <td>{p.stockMinimo || 5}</td>
                    <td>
                      <span className={`badge ${p.stock === 0 ? 'badge-danger' : 'badge-warning'}`}>
                        {p.stock === 0 ? 'Agotado' : 'Bajo'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
