import { useState, useEffect } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, PieChart, Pie, Cell } from 'recharts';
import { getDashboard } from '../lib/api';
import toast from 'react-hot-toast';

const COLORS = ['#2d6a4f', '#4dac7a', '#fbbf24', '#ef4444'];

const fmt = (n) => n >= 1e7 ? `₹${(n / 1e7).toFixed(1)}Cr` : n >= 1e5 ? `₹${(n / 1e5).toFixed(1)}L` : `₹${n?.toLocaleString('en-IN') || 0}`;
const fmtNum = (n) => n >= 1000 ? `${(n / 1000).toFixed(1)}K` : n || 0;

const STATUS_BADGE = {
    DELIVERED: <span className="badge badge-success">Delivered</span>,
    DISPATCHED: <span className="badge badge-info">Dispatched</span>,
    PROCESSING: <span className="badge badge-purple">Processing</span>,
    PAYMENT_CONFIRMED: <span className="badge badge-warning">Paid</span>,
    PENDING: <span className="badge badge-gray">Pending</span>,
    CANCELLED: <span className="badge badge-danger">Cancelled</span>,
};

export default function Dashboard() {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        getDashboard()
            .then(r => setData(r.data))
            .catch(() => toast.error('Failed to load dashboard'))
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <div className="page-loader"><div className="loading-spinner" /></div>;

    const s = data?.stats || {};
    const orders = data?.recentOrders || [];
    const trend = data?.revenueTrend || [];

    const pieData = [
        { name: 'Farmers', value: s.totalFarmers },
        { name: 'Suppliers', value: s.totalSuppliers },
    ];

    return (
        <div className="animate-fade">
            {/* Stats Grid */}
            <div className="stats-grid">
                {[
                    { icon: '👥', label: 'Total Users', value: fmtNum(s.totalUsers), change: `+${s.newUsersThisMonth || 0} this month`, color: '#dbeafe', up: true },
                    { icon: '🌾', label: 'Farmers', value: fmtNum(s.totalFarmers), change: 'Active farmers', color: '#dcfce7', up: true },
                    { icon: '🏪', label: 'Suppliers', value: fmtNum(s.totalSuppliers), change: `${s.pendingSuppliers || 0} pending verify`, color: '#fef9c3', up: false },
                    { icon: '📦', label: 'Total Orders', value: fmtNum(s.totalOrders), change: `${s.pendingOrders || 0} pending`, color: '#f3e8ff', up: true },
                    { icon: '💰', label: 'Revenue', value: fmt(s.totalRevenue), change: 'All-time GMV', color: '#dcfce7', up: true },
                    { icon: '🌿', label: 'Products', value: fmtNum(s.totalProducts), change: 'Active listings', color: '#fde8d8', up: true },
                ].map(card => (
                    <div className="stat-card" key={card.label}>
                        <div className="stat-card-header">
                            <div className="stat-card-icon" style={{ background: card.color }}>{card.icon}</div>
                            <span className={`stat-card-change ${card.up ? 'up' : 'down'}`}>{card.change}</span>
                        </div>
                        <div className="stat-card-value">{card.value}</div>
                        <div className="stat-card-label">{card.label}</div>
                    </div>
                ))}
            </div>

            {/* Charts row */}
            <div className="grid-2" style={{ marginBottom: 24 }}>
                <div className="card">
                    <div className="card-header">
                        <span className="card-title">📈 Revenue Trend (7 Days)</span>
                    </div>
                    <div className="card-body">
                        <ResponsiveContainer width="100%" height={220}>
                            <AreaChart data={trend} margin={{ top: 5, right: 0, left: -20, bottom: 0 }}>
                                <defs>
                                    <linearGradient id="revColor" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#2d6a4f" stopOpacity={0.3} />
                                        <stop offset="95%" stopColor="#2d6a4f" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" stroke="#f0faf4" />
                                <XAxis dataKey="date" tick={{ fontSize: 11 }} tickFormatter={d => d.slice(5)} />
                                <YAxis tick={{ fontSize: 11 }} tickFormatter={v => `₹${v >= 1000 ? (v / 1000).toFixed(0) + 'K' : v}`} />
                                <Tooltip formatter={(v) => [`₹${v.toLocaleString('en-IN')}`, 'Revenue']} />
                                <Area type="monotone" dataKey="revenue" stroke="#2d6a4f" strokeWidth={2.5} fill="url(#revColor)" />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                <div className="card">
                    <div className="card-header">
                        <span className="card-title">👥 User Distribution</span>
                    </div>
                    <div className="card-body" style={{ display: 'flex', alignItems: 'center', gap: 24 }}>
                        <PieChart width={160} height={160}>
                            <Pie data={pieData} cx={75} cy={75} innerRadius={45} outerRadius={70} paddingAngle={4} dataKey="value">
                                {pieData.map((_, i) => <Cell key={i} fill={COLORS[i]} />)}
                            </Pie>
                            <Tooltip />
                        </PieChart>
                        <div style={{ flex: 1 }}>
                            {pieData.map((d, i) => (
                                <div key={d.name} className="flex-center gap-8" style={{ marginBottom: 12 }}>
                                    <div style={{ width: 10, height: 10, borderRadius: '50%', background: COLORS[i] }} />
                                    <div>
                                        <div style={{ fontWeight: 600, fontSize: 14 }}>{d.name}</div>
                                        <div style={{ fontSize: 22, fontWeight: 800 }}>{d.value?.toLocaleString()}</div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            </div>

            {/* Recent Orders */}
            <div className="card">
                <div className="card-header">
                    <span className="card-title">🛒 Recent Orders</span>
                </div>
                <div className="card-body" style={{ padding: '16px 0 0' }}>
                    {orders.length === 0 ? (
                        <div className="empty-state"><div className="icon">📦</div><h3>No orders yet</h3></div>
                    ) : (
                        <div className="table-container">
                            <table>
                                <thead><tr>
                                    <th>Order ID</th><th>Farmer</th><th>Amount</th><th>Items</th><th>Status</th><th>Date</th>
                                </tr></thead>
                                <tbody>
                                    {orders.slice(0, 8).map(order => (
                                        <tr key={order.id}>
                                            <td style={{ fontFamily: 'monospace', fontSize: 12 }}>#{order.id.slice(-8).toUpperCase()}</td>
                                            <td>
                                                <div className="flex-center gap-8">
                                                    <div className="avatar avatar-sm">{order.farmer?.user?.name?.[0] || 'F'}</div>
                                                    <div>
                                                        <div style={{ fontWeight: 600, fontSize: 13 }}>{order.farmer?.user?.name}</div>
                                                        <div className="text-xs text-secondary">{order.farmer?.district}</div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td style={{ fontWeight: 700 }}>₹{order.totalAmount?.toLocaleString('en-IN')}</td>
                                            <td>{order.items?.length} item{order.items?.length !== 1 ? 's' : ''}</td>
                                            <td>{STATUS_BADGE[order.status] || <span className="badge badge-gray">{order.status}</span>}</td>
                                            <td className="text-secondary text-sm">{new Date(order.createdAt).toLocaleDateString('en-IN')}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
