import { useState, useEffect } from 'react';
import { getProducts, approveProduct, rejectProduct } from '../lib/api';
import toast from 'react-hot-toast';

const CATEGORIES = ['', 'SEEDS', 'FERTILIZER', 'PESTICIDE', 'EQUIPMENT', 'ORGANIC', 'OTHER'];

export default function Products() {
    const [products, setProducts] = useState([]);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [category, setCategory] = useState('');
    const [approved, setApproved] = useState('');
    const [page, setPage] = useState(1);
    const [actionLoading, setActionLoading] = useState(null); // 'approve-{id}' | 'reject-{id}'

    const load = () => {
        setLoading(true);
        getProducts({ page, limit: 20, search, category, isApproved: approved })
            .then(r => { setProducts(r.data); setTotal(r.pagination?.total || 0); })
            .catch(() => toast.error('Failed to load products'))
            .finally(() => setLoading(false));
    };

    useEffect(() => { load(); }, [page, search, category, approved]);

    const handleApprove = async (id) => {
        setActionLoading(`approve-${id}`);
        try {
            await approveProduct(id);
            setProducts(p => p.map(x => x.id === id ? { ...x, isApproved: true } : x));
            toast.success('Product approved');
        } catch { toast.error('Failed'); }
        finally { setActionLoading(null); }
    };

    const handleReject = async (id) => {
        setActionLoading(`reject-${id}`);
        try {
            await rejectProduct(id);
            setProducts(p => p.filter(x => x.id !== id));
            toast.success('Product rejected');
        } catch { toast.error('Failed'); }
        finally { setActionLoading(null); }
    };

    return (
        <div className="animate-fade">
            <div className="flex-between mb-24">
                <h3 style={{ fontSize: 16, fontWeight: 700 }}>Products <span style={{ color: 'var(--text-secondary)', fontWeight: 400 }}>({total})</span></h3>
                <div className="flex-center gap-8">
                    <div className="search-bar">
                        <span>🔍</span>
                        <input placeholder="Search products…" value={search} onChange={e => { setSearch(e.target.value); setPage(1); }} />
                    </div>
                    <select className="input" style={{ width: 140 }} value={category} onChange={e => { setCategory(e.target.value); setPage(1); }}>
                        <option value="">All Categories</option>
                        {CATEGORIES.slice(1).map(c => <option key={c} value={c}>{c}</option>)}
                    </select>
                    <select className="input" style={{ width: 140 }} value={approved} onChange={e => { setApproved(e.target.value); setPage(1); }}>
                        <option value="">All Status</option>
                        <option value="false">Pending Approval</option>
                        <option value="true">Approved</option>
                    </select>
                </div>
            </div>

            <div className="card">
                {loading ? <div className="page-loader"><div className="loading-spinner" /></div> : (
                    <div className="table-container">
                        <table>
                            <thead><tr><th>Product</th><th>Category</th><th>Supplier</th><th>Price</th><th>Stock</th><th>Status</th><th>Actions</th></tr></thead>
                            <tbody>
                                {products.length === 0 ? (
                                    <tr><td colSpan={7}><div className="empty-state"><div className="icon">🌿</div><h3>No products found</h3></div></td></tr>
                                ) : products.map(p => (
                                    <tr key={p.id}>
                                        <td>
                                            <div>
                                                <div style={{ fontWeight: 600, fontSize: 13 }}>{p.name}</div>
                                                {p.nameMarathi && <div className="text-xs text-secondary">{p.nameMarathi}</div>}
                                                {p.isOrganic && <span className="badge badge-success" style={{ marginTop: 2 }}>🌱 Organic</span>}
                                            </div>
                                        </td>
                                        <td><span className="badge badge-info">{p.category}</span></td>
                                        <td className="text-sm">{p.supplier?.user?.name || p.supplier?.businessName}</td>
                                        <td style={{ fontWeight: 700 }}>₹{p.price?.toLocaleString('en-IN')}<span className="text-xs text-secondary"> /{p.unit}</span></td>
                                        <td>
                                            <span className={p.stockQuantity < 10 ? 'text-danger font-bold' : ''}>{p.stockQuantity}</span>
                                        </td>
                                        <td>
                                            {p.isApproved ? <span className="badge badge-success">✅ Approved</span> : <span className="badge badge-warning">⏳ Pending</span>}
                                        </td>
                                        <td>
                                            {!p.isApproved ? (
                                                <div className="flex-center gap-8">
                                                    <button
                                                        className="btn btn-sm btn-success"
                                                        disabled={actionLoading === `approve-${p.id}`}
                                                        onClick={() => handleApprove(p.id)}
                                                    >
                                                        {actionLoading === `approve-${p.id}` ? <><span className="btn-spinner" /> Approving…</> : 'Approve'}
                                                    </button>
                                                    <button
                                                        className="btn btn-sm btn-danger"
                                                        disabled={actionLoading === `reject-${p.id}`}
                                                        onClick={() => handleReject(p.id)}
                                                    >
                                                        {actionLoading === `reject-${p.id}` ? <><span className="btn-spinner" /> Rejecting…</> : 'Reject'}
                                                    </button>
                                                </div>
                                            ) : (
                                                <button
                                                    className="btn btn-sm btn-outline"
                                                    disabled={actionLoading === `reject-${p.id}`}
                                                    onClick={() => handleReject(p.id)}
                                                >
                                                    {actionLoading === `reject-${p.id}` ? <><span className="btn-spinner" /> Removing…</> : 'Remove'}
                                                </button>
                                            )}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {total > 20 && (
                <div className="flex-center gap-8 mt-16" style={{ justifyContent: 'center' }}>
                    <button className="pagination-btn" onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}>‹</button>
                    <span style={{ fontSize: 14 }}>Page {page} of {Math.ceil(total / 20)}</span>
                    <button className="pagination-btn" onClick={() => setPage(p => p + 1)} disabled={page * 20 >= total}>›</button>
                </div>
            )}
        </div>
    );
}
