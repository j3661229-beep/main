import { useState, useEffect } from 'react';
import { getMandiPrices } from '../lib/api';
import toast from 'react-hot-toast';

export default function MandiPrices() {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [district, setDistrict] = useState('Nashik');

    useEffect(() => {
        setLoading(true);
        getMandiPrices({ district })
            .then(r => setData(r.data))
            .catch(() => toast.error('Failed to load mandi prices'))
            .finally(() => setLoading(false));
    }, [district]);

    const prices = data?.prices || [];

    return (
        <div className="animate-fade">
            <div className="flex-between mb-24">
                <div>
                    <h3 style={{ fontSize: 16, fontWeight: 700 }}>Live Mandi Prices</h3>
                    <p className="text-sm text-secondary">Source: AGMARKNET — data.gov.in</p>
                </div>
                <div className="flex-center gap-8">
                    <select className="input" style={{ width: 160 }} value={district} onChange={e => setDistrict(e.target.value)}>
                        {['Nashik', 'Pune', 'Aurangabad', 'Nagpur', 'Kolhapur', 'Solapur'].map(d => (
                            <option key={d} value={d}>{d}</option>
                        ))}
                    </select>
                    <button className="btn btn-primary" onClick={() => { setLoading(true); getMandiPrices({ district }).then(r => setData(r.data)).finally(() => setLoading(false)); }}>
                        🔄 Refresh
                    </button>
                </div>
            </div>

            {data && (
                <div className="flex-between mb-16">
                    <span className="text-sm text-secondary">Updated: {new Date(data.updatedAt).toLocaleTimeString('en-IN')}</span>
                    <span className="text-sm text-secondary">{data.source}</span>
                </div>
            )}

            {loading ? (
                <div className="page-loader"><div className="loading-spinner" /></div>
            ) : (
                <div className="stats-grid" style={{ gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))' }}>
                    {prices.map((p, i) => (
                        <div key={i} className="stat-card">
                            <div className="stat-card-header">
                                <span style={{ fontSize: 32 }}>{p.emoji || '🌾'}</span>
                                <span className={`stat-card-change ${p.trend === 'up' || p.change > 0 ? 'up' : 'down'}`}>
                                    {p.trend === 'up' || p.change > 0 ? '↑' : '↓'} {Math.abs(p.change || 0).toFixed(1)}%
                                </span>
                            </div>
                            <div className="stat-card-value" style={{ fontSize: 22 }}>
                                ₹{p.price?.toLocaleString('en-IN')}
                                <span style={{ fontSize: 12, color: 'var(--text-secondary)', fontWeight: 400 }}>/quintal</span>
                            </div>
                            <div className="stat-card-label">{p.crop}</div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
                                <span className="text-xs text-secondary">Yesterday: ₹{p.yesterday?.toLocaleString('en-IN')}</span>
                                <span className="text-xs text-secondary">{p.market}</span>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}
