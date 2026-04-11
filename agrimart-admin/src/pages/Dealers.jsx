import { useState, useEffect } from 'react';
import { getPendingDealers, getAllDealers, verifyDealer } from '../lib/api';
import toast from 'react-hot-toast';

const STATUS_MAP = {
    APPROVED: <span className="badge badge-success">Approved</span>,
    PENDING: <span className="badge badge-warning">Pending</span>,
    REJECTED: <span className="badge badge-danger">Rejected</span>,
};

export default function Dealers() {
    const [dealers, setDealers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selected, setSelected] = useState(null);
    const [rejectReason, setRejectReason] = useState('');
    const [tab, setTab] = useState('pending'); // 'pending' | 'all'
    const [search, setSearch] = useState('');

    const load = () => {
        setLoading(true);
        const req = tab === 'pending' ? getPendingDealers() : getAllDealers({ search });
        req
            .then(r => setDealers(r.data || []))
            .catch(() => toast.error('Failed to load dealers'))
            .finally(() => setLoading(false));
    };

    useEffect(() => { load(); }, [tab, search]);

    const handleVerify = async (id, action) => {
        try {
            await verifyDealer(id, { action, reason: rejectReason });
            toast.success(`Dealer ${action === 'approve' ? '✅ approved' : '❌ rejected'}`);
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
                            {t === 'pending' ? '⏳ Pending' : '📋 All Dealers'}
                        </button>
                    ))}
                </div>
                {tab === 'all' && (
                    <div className="search-bar">
                        <span>🔍</span>
                        <input placeholder="Search dealers…" value={search} onChange={e => setSearch(e.target.value)} />
                    </div>
                )}
            </div>

            {/* Stats banner */}
            <div className="flex-center gap-16 mb-24">
                <div className="stat-card" style={{ flex: '0 0 auto', padding: '16px 24px' }}>
                    <div className="flex-center gap-8">
                        <span style={{ fontSize: 28 }}>{tab === 'pending' ? '⏳' : '🤝'}</span>
                        <div>
                            <div style={{ fontSize: 26, fontWeight: 800 }}>{dealers.length}</div>
                            <div style={{ fontSize: 13, color: 'var(--text-secondary)' }}>
                                {tab === 'pending' ? 'Pending Verification' : 'Total Dealers'}
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div className="card">
                <div className="card-header">
                    <span className="card-title">
                        {tab === 'pending' ? '🤝 Pending Dealer Verification' : '🤝 All Dealers'}
                    </span>
                    <button className="btn btn-sm btn-outline" onClick={load}>↻ Refresh</button>
                </div>
                {loading ? (
                    <div className="page-loader"><div className="loading-spinner" /></div>
                ) : dealers.length === 0 ? (
                    <div className="empty-state">
                        <div className="icon">{tab === 'pending' ? '✅' : '🤝'}</div>
                        <h3>{tab === 'pending' ? 'All dealers verified!' : 'No dealers found'}</h3>
                        <p>{tab === 'pending' ? 'No pending verification requests.' : 'No dealers registered yet.'}</p>
                    </div>
                ) : (
                    <div className="table-container" style={{ padding: '0 0 16px' }}>
                        <table>
                            <thead>
                                <tr>
                                    <th>Business / Agency</th>
                                    <th>Contact</th>
                                    <th>Govt Document</th>
                                    <th>Location</th>
                                    {tab === 'all' && <th>Status</th>}
                                    <th>Joined</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {dealers.map(d => (
                                    <tr key={d.id}>
                                        <td>
                                            <div className="flex-center gap-8">
                                                <div className="avatar avatar-md" style={{ background: 'var(--blue-100)', color: 'var(--blue-600)' }}>🤝</div>
                                                <div>
                                                    <div style={{ fontWeight: 700 }}>{d.businessName}</div>
                                                    <div className="text-xs text-secondary">{d.user?.name}</div>
                                                </div>
                                            </div>
                                        </td>
                                        <td style={{ fontFamily: 'monospace', fontSize: 13 }}>{d.user?.phone || d.user?.email}</td>
                                        <td>
                                            {d.govtDocUrl ? (
                                                <a href={d.govtDocUrl} target="_blank" rel="noreferrer" className="flex-center gap-4 text-primary" style={{ fontSize: 13, textDecoration: 'none', fontWeight: 600 }}>
                                                    📄 {d.govtDocType || 'Document'}
                                                </a>
                                            ) : <span className="text-secondary text-xs">No doc uploaded</span>}
                                        </td>
                                        <td className="text-secondary text-sm">{d.district}, {d.state}</td>
                                        {tab === 'all' && <td>{STATUS_MAP[d.docStatus] || <span className="badge badge-gray">Unknown</span>}</td>}
                                        <td className="text-secondary text-sm">{new Date(d.createdAt).toLocaleDateString('en-IN')}</td>
                                        <td>
                                            <div className="flex-center gap-8">
                                                {d.docStatus === 'PENDING' && (
                                                    <>
                                                        <button className="btn btn-sm btn-success" onClick={() => handleVerify(d.id, 'approve')}>✅ Approve</button>
                                                        <button className="btn btn-sm btn-danger" onClick={() => setSelected(d)}>❌ Reject</button>
                                                    </>
                                                )}
                                                {d.docStatus === 'APPROVED' && (
                                                    <span className="text-xs text-secondary">Verified</span>
                                                )}
                                                {d.docStatus === 'REJECTED' && (
                                                    <span className="text-xs text-danger">Rejected</span>
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
                            <h3 className="modal-title">Reject Dealer</h3>
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
                                    placeholder="e.g., Invalid document, incorrect details..."
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
