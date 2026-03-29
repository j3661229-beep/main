import { useState, useEffect } from 'react';
import { getPendingSuppliers, getAllSuppliers, verifySupplier } from '../lib/api';
import toast from 'react-hot-toast';

const STATUS_MAP = {
    VERIFIED: <span className="badge badge-success">Verified</span>,
    PENDING: <span className="badge badge-warning">Pending</span>,
    REJECTED: <span className="badge badge-danger">Rejected</span>,
};

export default function Suppliers() {
    const [suppliers, setSuppliers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selected, setSelected] = useState(null);
    const [rejectReason, setRejectReason] = useState('');
    const [tab, setTab] = useState('pending'); // 'pending' | 'all'
    const [search, setSearch] = useState('');

    const load = () => {
        setLoading(true);
        const req = tab === 'pending' ? getPendingSuppliers() : getAllSuppliers({ search });
        req
            .then(r => setSuppliers(r.data || []))
            .catch(() => toast.error('Failed to load suppliers'))
            .finally(() => setLoading(false));
    };

    useEffect(() => { load(); }, [tab, search]);

    const handleVerify = async (id, action) => {
        try {
            await verifySupplier(id, { action, reason: rejectReason });
            toast.success(`Supplier ${action === 'approve' ? '✅ approved' : '❌ rejected'}`);
            setSelected(null);
            setRejectReason('');
            load();
        } catch { toast.error('Action failed'); }
    };

    return (
        <div className="animate-fade">
            {/* Tab bar */}
            <div className="flex-between mb-24">
                <div className="flex-center gap-8">
                    {['pending', 'all'].map(t => (
                        <button key={t} onClick={() => setTab(t)}
                            className={`btn btn-sm ${tab === t ? 'btn-primary' : 'btn-outline'}`}>
                            {t === 'pending' ? '⏳ Pending' : '📋 All Suppliers'}
                        </button>
                    ))}
                </div>
                {tab === 'all' && (
                    <div className="search-bar">
                        <span>🔍</span>
                        <input placeholder="Search suppliers…" value={search} onChange={e => setSearch(e.target.value)} />
                    </div>
                )}
            </div>

            {/* Stats banner */}
            <div className="flex-center gap-16 mb-24">
                <div className="stat-card" style={{ flex: '0 0 auto', padding: '16px 24px' }}>
                    <div className="flex-center gap-8">
                        <span style={{ fontSize: 28 }}>{tab === 'pending' ? '⏳' : '🏪'}</span>
                        <div>
                            <div style={{ fontSize: 26, fontWeight: 800 }}>{suppliers.length}</div>
                            <div style={{ fontSize: 13, color: 'var(--text-secondary)' }}>
                                {tab === 'pending' ? 'Pending Verification' : 'Total Suppliers'}
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="card">
                <div className="card-header">
                    <span className="card-title">
                        {tab === 'pending' ? '🏪 Pending Supplier Verification' : '🏪 All Suppliers'}
                    </span>
                    <button className="btn btn-sm btn-outline" onClick={load}>↻ Refresh</button>
                </div>
                {loading ? (
                    <div className="page-loader"><div className="loading-spinner" /></div>
                ) : suppliers.length === 0 ? (
                    <div className="empty-state">
                        <div className="icon">{tab === 'pending' ? '✅' : '🏪'}</div>
                        <h3>{tab === 'pending' ? 'All suppliers verified!' : 'No suppliers found'}</h3>
                        <p>{tab === 'pending' ? 'No pending verification requests.' : 'No suppliers registered yet.'}</p>
                    </div>
                ) : (
                    <div className="table-container" style={{ padding: '0 0 16px' }}>
                        <table>
                            <thead>
                                <tr>
                                    <th>Business</th>
                                    <th>Contact</th>
                                    <th>GST</th>
                                    <th>Location</th>
                                    {tab === 'all' && <th>Status</th>}
                                    <th>Joined</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {suppliers.map(s => (
                                    <tr key={s.id}>
                                        <td>
                                            <div className="flex-center gap-8">
                                                <div className="avatar avatar-md" style={{ background: 'var(--green-100)' }}>🏪</div>
                                                <div>
                                                    <div style={{ fontWeight: 700 }}>{s.businessName}</div>
                                                    <div className="text-xs text-secondary">{s.user?.name}</div>
                                                </div>
                                            </div>
                                        </td>
                                        <td style={{ fontFamily: 'monospace', fontSize: 13 }}>{s.user?.phone}</td>
                                        <td className="text-sm">{s.gstNumber || '—'}</td>
                                        <td className="text-secondary text-sm">{s.district}, {s.pincode}</td>
                                        {tab === 'all' && <td>{STATUS_MAP[s.verificationStatus] || <span className="badge badge-gray">Unknown</span>}</td>}
                                        <td className="text-secondary text-sm">{new Date(s.createdAt).toLocaleDateString('en-IN')}</td>
                                        <td>
                                            <div className="flex-center gap-8">
                                                {s.verificationStatus !== 'VERIFIED' && (
                                                    <button className="btn btn-sm btn-success" onClick={() => handleVerify(s.id, 'approve')}>✅ Approve</button>
                                                )}
                                                {s.verificationStatus !== 'REJECTED' && (
                                                    <button className="btn btn-sm btn-danger" onClick={() => setSelected(s)}>❌ Reject</button>
                                                )}
                                                {s.verificationStatus === 'VERIFIED' && s.verificationStatus !== 'REJECTED' && (
                                                    <span className="text-xs text-secondary">Verified</span>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Reject modal */}
            {selected && (
                <div className="modal-overlay" onClick={() => setSelected(null)}>
                    <div className="modal" onClick={e => e.stopPropagation()}>
                        <div className="modal-header">
                            <h3 className="modal-title">Reject Supplier</h3>
                            <button style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 20 }} onClick={() => setSelected(null)}>✕</button>
                        </div>
                        <div className="modal-body">
                            <p style={{ marginBottom: 16, color: 'var(--text-secondary)' }}>
                                Rejecting <strong>{selected.businessName}</strong>. Please provide a reason:
                            </p>
                            <div className="input-group">
                                <label className="input-label">Rejection Reason</label>
                                <textarea
                                    className="input"
                                    rows={3}
                                    placeholder="e.g., Invalid GST, incomplete documents..."
                                    value={rejectReason}
                                    onChange={e => setRejectReason(e.target.value)}
                                />
                            </div>
                        </div>
                        <div className="modal-footer">
                            <button className="btn btn-outline" onClick={() => setSelected(null)}>Cancel</button>
                            <button className="btn btn-danger" onClick={() => handleVerify(selected.id, 'reject')}>Confirm Reject</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
