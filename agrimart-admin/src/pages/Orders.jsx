import { useState, useEffect } from 'react';
import { getOrders } from '../lib/api';
import toast from 'react-hot-toast';

const STATUS_CONFIG = {
    PENDING: { badge: 'badge-warning', label: 'Pending' },
    PAYMENT_CONFIRMED: { badge: 'badge-info', label: 'Paid' },
    PROCESSING: { badge: 'badge-purple', label: 'Processing' },
    DISPATCHED: { badge: 'badge-info', label: 'Dispatched' },
    OUT_FOR_DELIVERY: { badge: 'badge-info', label: 'Out for Delivery' },
    DELIVERED: { badge: 'badge-success', label: 'Delivered' },
    CANCELLED: { badge: 'badge-danger', label: 'Cancelled' },
    REFUNDED: { badge: 'badge-gray', label: 'Refunded' },
};

export default function Orders() {
    const [orders, setOrders] = useState([]);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(true);
    const [status, setStatus] = useState('');
    const [page, setPage] = useState(1);
    const [selected, setSelected] = useState(null);

    const load = () => {
        setLoading(true);
        getOrders({ page, limit: 20, status })
            .then(r => { setOrders(r.data); setTotal(r.pagination?.total || 0); })
            .catch(() => toast.error('Failed to load orders'))
            .finally(() => setLoading(false));
    };

    useEffect(() => { load(); }, [page, status]);

    return (
        <div className="animate-fade">
            <div className="flex-between mb-24">
                <h3 style={{ fontSize: 16, fontWeight: 700 }}>All Orders <span style={{ color: 'var(--text-secondary)', fontWeight: 400 }}>({total})</span></h3>
                <select className="input" style={{ width: 180 }} value={status} onChange={e => { setStatus(e.target.value); setPage(1); }}>
                    <option value="">All Status</option>
                    {Object.entries(STATUS_CONFIG).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
                </select>
            </div>

            <div className="card">
                {loading ? <div className="page-loader"><div className="loading-spinner" /></div> : (
                    <div className="table-container">
                        <table>
                            <thead><tr><th>Order ID</th><th>Farmer</th><th>Items</th><th>Amount</th><th>Payment</th><th>Status</th><th>Date</th><th>Detail</th></tr></thead>
                            <tbody>
                                {orders.length === 0 ? (
                                    <tr><td colSpan={8}><div className="empty-state"><div className="icon">📦</div><h3>No orders found</h3></div></td></tr>
                                ) : orders.map(o => {
                                    const cfg = STATUS_CONFIG[o.status] || { badge: 'badge-gray', label: o.status };
                                    return (
                                        <tr key={o.id}>
                                            <td style={{ fontFamily: 'monospace', fontSize: 12 }}>#{o.id.slice(-8).toUpperCase()}</td>
                                            <td>
                                                <div className="flex-center gap-8">
                                                    <div className="avatar avatar-sm">{o.farmer?.user?.name?.[0] || 'F'}</div>
                                                    <div>
                                                        <div style={{ fontWeight: 600, fontSize: 13 }}>{o.farmer?.user?.name}</div>
                                                        <div className="text-xs text-secondary">{o.farmer?.district}</div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td>{o.items?.length} item{o.items?.length !== 1 ? 's' : ''}</td>
                                            <td style={{ fontWeight: 700 }}>₹{o.totalAmount?.toLocaleString('en-IN')}</td>
                                            <td>
                                                <span className={`badge ${o.paymentStatus === 'SUCCESS' ? 'badge-success' : o.paymentStatus === 'FAILED' ? 'badge-danger' : 'badge-warning'}`}>
                                                    {o.payment?.method || o.paymentStatus || 'Pending'}
                                                </span>
                                            </td>
                                            <td><span className={`badge ${cfg.badge}`}>{cfg.label}</span></td>
                                            <td className="text-secondary text-sm">{new Date(o.createdAt).toLocaleDateString('en-IN')}</td>
                                            <td>
                                                <button className="btn btn-sm btn-outline" onClick={() => setSelected(o)}>View</button>
                                            </td>
                                        </tr>
                                    );
                                })}
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

            {/* Order detail modal */}
            {selected && (
                <div className="modal-overlay" onClick={() => setSelected(null)}>
                    <div className="modal" style={{ maxWidth: 640 }} onClick={e => e.stopPropagation()}>
                        <div className="modal-header">
                            <h3 className="modal-title">Order #{selected.id.slice(-8).toUpperCase()}</h3>
                            <button style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 20 }} onClick={() => setSelected(null)}>✕</button>
                        </div>
                        <div className="modal-body">
                            <div className="grid-2 mb-16">
                                <div><div className="text-xs text-secondary">Farmer</div><div style={{ fontWeight: 600 }}>{selected.farmer?.user?.name}</div></div>
                                <div><div className="text-xs text-secondary">Phone</div><div style={{ fontFamily: 'monospace' }}>{selected.farmer?.user?.phone}</div></div>
                                <div><div className="text-xs text-secondary">Amount</div><div style={{ fontWeight: 700, color: 'var(--color-primary)' }}>₹{selected.totalAmount?.toLocaleString('en-IN')}</div></div>
                                <div><div className="text-xs text-secondary">Address</div><div className="text-sm">{selected.deliveryAddress}</div></div>
                            </div>
                            <div style={{ fontWeight: 600, marginBottom: 8 }}>Order Items</div>
                            {selected.items?.map(item => (
                                <div key={item.id} className="flex-between" style={{ padding: '8px 0', borderBottom: '1px solid var(--border-color)' }}>
                                    <div>
                                        <div style={{ fontWeight: 500 }}>{item.product?.name}</div>
                                        <div className="text-xs text-secondary">Qty: {item.quantity} × ₹{item.product?.price}</div>
                                    </div>
                                    <div style={{ fontWeight: 700 }}>₹{item.price?.toLocaleString('en-IN')}</div>
                                </div>
                            ))}
                        </div>
                        <div className="modal-footer"><button className="btn btn-outline" onClick={() => setSelected(null)}>Close</button></div>
                    </div>
                </div>
            )}
        </div>
    );
}
