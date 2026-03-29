import { useState, useEffect } from 'react';
import { createScheme, updateScheme, deleteScheme } from '../lib/api';
import toast from 'react-hot-toast';

const EMPTY = { title: '', ministry: '', description: '', benefits: '', eligibility: '', documents: '', applyUrl: '', deadline: '' };

export default function Schemes() {
    const [schemes, setSchemes] = useState([]);
    const [loading, setLoading] = useState(true);
    const [modal, setModal] = useState(null); // null | 'create' | scheme-object
    const [form, setForm] = useState(EMPTY);
    const [saving, setSaving] = useState(false);

    useEffect(() => {
        // public endpoint — no admin auth needed
        fetch(`${import.meta.env.VITE_API_URL || 'http://localhost:3000/api'}/schemes`)
            .then(r => r.json())
            .then(r => setSchemes(r.data || []))
            .catch(() => toast.error('Failed to load schemes'))
            .finally(() => setLoading(false));
    }, []);

    const openCreate = () => { setForm(EMPTY); setModal('create'); };
    const openEdit = (s) => {
        setForm({ title: s.title, ministry: s.ministry, description: s.description, benefits: s.benefits, eligibility: s.eligibility, documents: s.documents?.join(', ') || '', applyUrl: s.applyUrl || '', deadline: s.deadline ? s.deadline.split('T')[0] : '' });
        setModal(s);
    };

    const handleSave = async () => {
        setSaving(true);
        const payload = { ...form, documents: form.documents.split(',').map(d => d.trim()).filter(Boolean) };
        try {
            if (modal === 'create') {
                const res = await createScheme(payload);
                setSchemes(s => [res.data, ...s]);
                toast.success('Scheme created');
            } else {
                const res = await updateScheme(modal.id, payload);
                setSchemes(s => s.map(x => x.id === modal.id ? res.data : x));
                toast.success('Scheme updated');
            }
            setModal(null);
        } catch { toast.error('Save failed'); }
        finally { setSaving(false); }
    };

    const handleDelete = async (id) => {
        if (!confirm('Delete this scheme?')) return;
        try {
            await deleteScheme(id);
            setSchemes(s => s.filter(x => x.id !== id));
            toast.success('Scheme deleted');
        } catch { toast.error('Delete failed'); }
    };

    return (
        <div className="animate-fade">
            <div className="flex-between mb-24">
                <h3 style={{ fontSize: 16, fontWeight: 700 }}>Government Schemes ({schemes.length})</h3>
                <button className="btn btn-primary" onClick={openCreate}>➕ Add Scheme</button>
            </div>

            {loading ? <div className="page-loader"><div className="loading-spinner" /></div> :
                schemes.length === 0 ? (
                    <div className="card"><div className="empty-state"><div className="icon">🏛️</div><h3>No schemes yet</h3><p>Add government schemes for farmers</p></div></div>
                ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                        {schemes.map(s => (
                            <div key={s.id} className="card card-body" style={{ display: 'flex', alignItems: 'flex-start', gap: 16 }}>
                                <div style={{ fontSize: 36 }}>🏛️</div>
                                <div style={{ flex: 1 }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
                                        <h3 style={{ fontSize: 15, fontWeight: 700 }}>{s.title}</h3>
                                        <span className={`badge ${s.isActive ? 'badge-success' : 'badge-gray'}`}>{s.isActive ? 'Active' : 'Inactive'}</span>
                                    </div>
                                    <div className="text-sm text-secondary">{s.ministry}</div>
                                    <div style={{ marginTop: 8, fontSize: 14 }}><strong>Benefits:</strong> {s.benefits}</div>
                                    <div style={{ fontSize: 14 }}><strong>Eligibility:</strong> {s.eligibility}</div>
                                    {s.documents?.length > 0 && (
                                        <div style={{ marginTop: 6, display: 'flex', gap: 4, flexWrap: 'wrap' }}>
                                            {s.documents.map(d => <span key={d} className="badge badge-info">{d}</span>)}
                                        </div>
                                    )}
                                    {s.applyUrl && <a href={s.applyUrl} target="_blank" rel="noreferrer" style={{ fontSize: 13, color: 'var(--color-primary)', marginTop: 6, display: 'block' }}>🔗 Apply Online</a>}
                                </div>
                                <div className="flex-center gap-8">
                                    <button className="btn btn-sm btn-outline" onClick={() => openEdit(s)}>✏️ Edit</button>
                                    <button className="btn btn-sm btn-danger" onClick={() => handleDelete(s.id)}>🗑️</button>
                                </div>
                            </div>
                        ))}
                    </div>
                )
            }

            {/* Modal */}
            {modal !== null && (
                <div className="modal-overlay" onClick={() => setModal(null)}>
                    <div className="modal" style={{ maxWidth: 600 }} onClick={e => e.stopPropagation()}>
                        <div className="modal-header">
                            <h3 className="modal-title">{modal === 'create' ? 'Add Scheme' : 'Edit Scheme'}</h3>
                            <button style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 20 }} onClick={() => setModal(null)}>✕</button>
                        </div>
                        <div className="modal-body">
                            {[['title', 'Scheme Title'], ['ministry', 'Ministry'], ['benefits', 'Benefits'], ['eligibility', 'Eligibility Criteria'], ['documents', 'Documents Required (comma-separated)'], ['applyUrl', 'Apply URL'], ['deadline', 'Deadline']].map(([key, label]) => (
                                <div key={key} className="input-group" style={{ marginBottom: 12 }}>
                                    <label className="input-label">{label}</label>
                                    <input
                                        className="input"
                                        type={key === 'deadline' ? 'date' : 'text'}
                                        value={form[key]}
                                        onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}
                                        placeholder={label}
                                    />
                                </div>
                            ))}
                            <div className="input-group">
                                <label className="input-label">Description</label>
                                <textarea className="input" rows={3} value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} />
                            </div>
                        </div>
                        <div className="modal-footer">
                            <button className="btn btn-outline" onClick={() => setModal(null)}>Cancel</button>
                            <button className="btn btn-primary" onClick={handleSave} disabled={saving}>{saving ? 'Saving…' : 'Save Scheme'}</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
