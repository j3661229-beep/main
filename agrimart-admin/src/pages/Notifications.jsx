import { useState } from 'react';
import { broadcastNotification } from '../lib/api';
import toast from 'react-hot-toast';

const TEMPLATES = [
    { title: '🌧️ Weather Alert', body: 'Heavy rainfall expected in your district tomorrow. Avoid spraying fertilizers.', type: 'WEATHER' },
    { title: '🏛️ New PM-KISAN Installment', body: 'PM-KISAN 17th installment has been released. Check your bank account.', type: 'SCHEME' },
    { title: '📈 Onion Price Alert', body: 'Onion prices increased by 15% at Nashik APMC today. Good time to sell!', type: 'PRICE_ALERT' },
    { title: '🌱 Sowing Season Reminder', body: 'Kharif sowing season begins next week. Prepare your seeds and fertilizers.', type: 'ADVISORY' },
];

export default function Notifications() {
    const [form, setForm] = useState({ title: '', body: '', targetType: 'all', district: '', type: 'GENERAL' });
    const [sending, setSending] = useState(false);
    const [sentCount, setSentCount] = useState(null);

    const handleTemplate = (t) => setForm(f => ({ ...f, ...t }));

    const handleSend = async () => {
        if (!form.title || !form.body) { toast.error('Title and body required'); return; }
        setSending(true);
        try {
            const res = await broadcastNotification(form);
            setSentCount(res.data?.sent || 0);
            toast.success(`Sent to ${res.data?.sent || 0} users!`);
            setForm(f => ({ ...f, title: '', body: '' }));
        } catch { toast.error('Failed to send notification'); }
        finally { setSending(false); }
    };

    return (
        <div className="animate-fade">
            <div className="grid-2" style={{ alignItems: 'start' }}>
                {/* Compose */}
                <div className="card card-body">
                    <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 20 }}>📢 Broadcast Notification</h3>

                    <div className="input-group" style={{ marginBottom: 12 }}>
                        <label className="input-label">Target Audience</label>
                        <select className="input" value={form.targetType} onChange={e => setForm(f => ({ ...f, targetType: e.target.value }))}>
                            <option value="all">All Users</option>
                            <option value="farmers">Farmers Only</option>
                            <option value="suppliers">Suppliers Only</option>
                        </select>
                    </div>

                    <div className="input-group" style={{ marginBottom: 12 }}>
                        <label className="input-label">District (optional)</label>
                        <input className="input" placeholder="e.g. Nashik (leave blank for all)" value={form.district} onChange={e => setForm(f => ({ ...f, district: e.target.value }))} />
                    </div>

                    <div className="input-group" style={{ marginBottom: 12 }}>
                        <label className="input-label">Notification Type</label>
                        <select className="input" value={form.type} onChange={e => setForm(f => ({ ...f, type: e.target.value }))}>
                            {['GENERAL', 'WEATHER', 'SCHEME', 'PRICE_ALERT', 'ADVISORY', 'ORDER'].map(t => <option key={t} value={t}>{t}</option>)}
                        </select>
                    </div>

                    <div className="input-group" style={{ marginBottom: 12 }}>
                        <label className="input-label">Title</label>
                        <input className="input" placeholder="Notification title…" value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value }))} />
                    </div>

                    <div className="input-group" style={{ marginBottom: 20 }}>
                        <label className="input-label">Message Body</label>
                        <textarea className="input" rows={4} placeholder="Your notification message…" value={form.body} onChange={e => setForm(f => ({ ...f, body: e.target.value }))} />
                    </div>

                    <button className="btn btn-primary w-full" style={{ justifyContent: 'center' }} onClick={handleSend} disabled={sending}>
                        {sending ? <><span className="btn-spinner" /> Sending…</> : '🚀 Send Broadcast'}
                    </button>

                    {sentCount !== null && (
                        <div style={{ marginTop: 16, padding: '12px 16px', background: 'var(--green-50)', borderRadius: 8, textAlign: 'center', fontWeight: 600, color: 'var(--green-700)' }}>
                            ✅ Sent to {sentCount} users
                        </div>
                    )}
                </div>

                {/* Templates */}
                <div>
                    <div className="card card-body">
                        <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 16 }}>⚡ Quick Templates</h3>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                            {TEMPLATES.map((t, i) => (
                                <div key={i} style={{
                                    padding: '12px 16px', background: 'var(--bg-body)', borderRadius: 10,
                                    cursor: 'pointer', border: '1.5px solid var(--border-color)',
                                    transition: 'all 0.2s',
                                }}
                                    onClick={() => handleTemplate(t)}
                                    onMouseEnter={e => e.currentTarget.style.borderColor = 'var(--color-primary)'}
                                    onMouseLeave={e => e.currentTarget.style.borderColor = 'var(--border-color)'}
                                >
                                    <div style={{ fontWeight: 600, fontSize: 14, marginBottom: 4 }}>{t.title}</div>
                                    <div style={{ fontSize: 12, color: 'var(--text-secondary)', lineHeight: 1.4 }}>{t.body.slice(0, 60)}…</div>
                                    <div style={{ marginTop: 6 }}><span className="badge badge-info" style={{ fontSize: 10 }}>{t.type}</span></div>
                                </div>
                            ))}
                        </div>
                    </div>

                    <div className="card card-body" style={{ marginTop: 16 }}>
                        <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 12 }}>📊 Reach Estimates</h3>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                            {[['All Users', '👥', '12,450'], ['Farmers', '🌾', '9,230'], ['NaShik District', '📍', '2,840']].map(([label, icon, count]) => (
                                <div key={label} className="flex-between" style={{ padding: '8px 0', borderBottom: '1px solid var(--border-color)' }}>
                                    <div className="flex-center gap-8"><span>{icon}</span><span className="text-sm">{label}</span></div>
                                    <span style={{ fontWeight: 700 }}>{count}</span>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
