import { useState, useEffect } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, PieChart, Pie, Cell, LineChart, Line } from 'recharts';
import { getDashboard } from '../lib/api'; // Reusing dashboard data for demonstration or adding dedicated API
import toast from 'react-hot-toast';

const COLORS = ['#2d6a4f', '#4dac7a', '#fbbf24', '#ef4444', '#3b82f6'];

export default function Analytics() {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [dateRange, setDateRange] = useState('7d');

    useEffect(() => {
        setLoading(true);
        getDashboard() // In a real app, this would be a specific analytics endpoint
            .then(r => setData(r.data))
            .catch(() => toast.error('Failed to load analytics data'))
            .finally(() => setLoading(false));
    }, [dateRange]);

    if (loading) return <div className="page-loader"><div className="loading-spinner" /></div>;

    const stats = data?.stats || {};
    const trend = data?.revenueTrend || [];

    const categoryData = [
        { name: 'Seeds', value: 400 },
        { name: 'Fertilizers', value: 300 },
        { name: 'Pesticides', value: 200 },
        { name: 'Dealers', value: 150 }, // Mock data for now
        { name: 'Equipment', value: 100 },
    ];

    return (
        <div className="animate-fade">
            <div className="flex-between mb-24">
                <h2 className="card-title" style={{ fontSize: 24 }}>📈 Platform Analytics</h2>
                <div className="flex-center gap-12">
                    <select
                        className="input"
                        value={dateRange}
                        onChange={(e) => setDateRange(e.target.value)}
                        style={{ width: 140, padding: '8px 12px' }}
                    >
                        <option value="7d">Last 7 Days</option>
                        <option value="30d">Last 30 Days</option>
                        <option value="90d">Last 90 Days</option>
                        <option value="1y">Last 1 Year</option>
                    </select>
                    <button className="btn btn-primary" onClick={() => toast.success('Exporting CSV...')}>
                        📥 Export Data
                    </button>
                </div>
            </div>

            {/* Top Metrics */}
            <div className="stats-grid mb-24">
                <div className="stat-card">
                    <div className="stat-card-label">Conversion Rate</div>
                    <div className="stat-card-value">3.2%</div>
                    <div className="stat-card-change up">+0.5% vs last period</div>
                </div>
                <div className="stat-card">
                    <div className="stat-card-label">Avg. Order Value</div>
                    <div className="stat-card-value">₹2,450</div>
                    <div className="stat-card-change down">-1.2% vs last period</div>
                </div>
                <div className="stat-card">
                    <div className="stat-card-label">Customer Retention</div>
                    <div className="stat-card-value">68%</div>
                    <div className="stat-card-change up">+4% vs last period</div>
                </div>
                <div className="stat-card">
                    <div className="stat-card-label">Dealers Active</div>
                    <div className="stat-card-value">{stats.totalDealers || 0}</div>
                    <div className="stat-card-change up">Healthy growth</div>
                </div>
            </div>

            <div className="grid-2 mb-24">
                {/* Revenue Growth */}
                <div className="card">
                    <div className="card-header">
                        <span className="card-title">💰 Revenue Growth</span>
                    </div>
                    <div className="card-body">
                        <ResponsiveContainer width="100%" height={300}>
                            <AreaChart data={trend}>
                                <defs>
                                    <linearGradient id="colorRev" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#2d6a4f" stopOpacity={0.8} />
                                        <stop offset="95%" stopColor="#2d6a4f" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <XAxis dataKey="date" hide />
                                <YAxis hide />
                                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#eee" />
                                <Tooltip />
                                <Area type="monotone" dataKey="amount" stroke="#2d6a4f" fillOpacity={1} fill="url(#colorRev)" />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* Sales by Category */}
                <div className="card">
                    <div className="card-header">
                        <span className="card-title">🛒 Sales by Category</span>
                    </div>
                    <div className="card-body flex-center">
                        <ResponsiveContainer width="100%" height={300}>
                            <PieChart>
                                <Pie
                                    data={categoryData}
                                    innerRadius={60}
                                    outerRadius={100}
                                    paddingAngle={5}
                                    dataKey="value"
                                >
                                    {categoryData.map((entry, index) => (
                                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                    ))}
                                </Pie>
                                <Tooltip />
                            </PieChart>
                        </ResponsiveContainer>
                        <div style={{ marginLeft: 20 }}>
                            {categoryData.map((c, i) => (
                                <div key={c.name} className="flex-center gap-8 mb-8" style={{ fontSize: 13 }}>
                                    <div style={{ width: 12, height: 12, borderRadius: 3, background: COLORS[i % COLORS.length] }} />
                                    <span>{c.name}: <strong>{c.value}</strong></span>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            </div>

            <div className="card">
                <div className="card-header">
                    <span className="card-title">📈 User Acquisition</span>
                </div>
                <div className="card-body">
                    <ResponsiveContainer width="100%" height={300}>
                        <BarChart data={trend}>
                            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#eee" />
                            <XAxis dataKey="date" hide />
                            <YAxis />
                            <Tooltip />
                            <Bar dataKey="orders" fill="#4dac7a" radius={[4, 4, 0, 0]} />
                        </BarChart>
                    </ResponsiveContainer>
                </div>
            </div>
        </div>
    );
}
