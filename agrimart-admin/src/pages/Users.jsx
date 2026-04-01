import { useState, useEffect } from 'react';
import { getUsers, toggleUser } from '../lib/api';
import toast from 'react-hot-toast';

export default function Users() {
    const [users, setUsers] = useState([]);
    const [total, setTotal] = useState(0);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [role, setRole] = useState('');
    const [page, setPage] = useState(1);

    const load = () => {
        setLoading(true);
        getUsers({ page, limit: 20, search, role })
            .then(r => { setUsers(r.data); setTotal(r.pagination?.total || 0); })
            .catch(() => toast.error('Failed to load users'))
            .finally(() => setLoading(false));
    };

    useEffect(() => { load(); }, [page, search, role]);

    const handleToggle = async (id) => {
        try {
            const res = await toggleUser(id);
            setUsers(u => u.map(x => x.id === id ? { ...x, isActive: res.data.isActive } : x));
            toast.success('User status updated');
        } catch { toast.error('Failed to update user'); }
    };

    return (
        <div className="animate-fade">
            {/* Header */}
            <div className="flex-between mb-24">
                <div>
                    <h3 style={{ fontSize: 16, fontWeight: 700 }}>All Users <span style={{ color: 'var(--text-secondary)', fontWeight: 400 }}>({total})</span></h3>
                </div>
                <div className="flex-center gap-8">
                    <div className="search-bar">
                        <span>🔍</span>
                        <input placeholder="Search name or phone…" value={search} onChange={e => { setSearch(e.target.value); setPage(1); }} />
                    </div>
                    <select className="input" style={{ width: 130 }} value={role} onChange={e => { setRole(e.target.value); setPage(1); }}>
                        <option value="">All Roles</option>
                        <option value="FARMER">Farmers</option>
                        <option value="DEALER">Dealers</option>
                        <option value="SUPPLIER">Suppliers</option>
                        <option value="ADMIN">Admins</option>
                    </select>
                </div>
            </div>

            <div className="card">
                {loading ? (
                    <div className="page-loader"><div className="loading-spinner" /></div>
                ) : users.length === 0 ? (
                    <div className="empty-state"><div className="icon">👥</div><h3>No users found</h3><p>Try adjusting your search</p></div>
                ) : (
                    <div className="table-container">
                        <table>
                            <thead><tr><th>User</th><th>Phone</th><th>Role</th><th>Location</th><th>Joined</th><th>Status</th><th>Actions</th></tr></thead>
                            <tbody>
                                {users.map(u => (
                                    <tr key={u.id}>
                                        <td>
                                            <div className="flex-center gap-8">
                                                <div className="avatar avatar-sm">{u.name?.[0] || '?'}</div>
                                                <span style={{ fontWeight: 600, fontSize: 13 }}>{u.name}</span>
                                            </div>
                                        </td>
                                        <td style={{ fontFamily: 'monospace', fontSize: 13 }}>{u.phone}</td>
                                        <td>
                                            <span className={`badge ${u.role === 'FARMER' ? 'badge-success' : u.role === 'DEALER' ? 'badge-warning' : u.role === 'SUPPLIER' ? 'badge-info' : 'badge-purple'}`}>{u.role}</span>
                                        </td>
                                        <td className="text-secondary text-sm">{u.farmer?.district || u.dealer?.district || u.supplier?.district || '—'}</td>
                                        <td className="text-secondary text-sm">{new Date(u.createdAt).toLocaleDateString('en-IN')}</td>
                                        <td>
                                            <div className="flex-center gap-4">
                                                <div className={`status-dot ${u.isActive ? 'active' : 'inactive'}`} />
                                                <span className="text-sm">{u.isActive ? 'Active' : 'Blocked'}</span>
                                            </div>
                                        </td>
                                        <td>
                                            <button
                                                className={`btn btn-sm ${u.isActive ? 'btn-danger' : 'btn-success'}`}
                                                onClick={() => handleToggle(u.id)}
                                            >
                                                {u.isActive ? '🚫 Block' : '✅ Unblock'}
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Pagination */}
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
