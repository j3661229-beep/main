import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import toast from 'react-hot-toast';

export default function Login() {
    const { login } = useAuth();
    const navigate = useNavigate();
    const [form, setForm] = useState({ phone: '+919999999999', password: 'AgriMart@Admin2024' });
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        try {
            await login(form.phone, form.password);
            toast.success('Welcome back, Admin!');
            navigate('/dashboard');
        } catch (err) {
            toast.error(err?.message || 'Login failed');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={{
            minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: 'linear-gradient(135deg, #1a4231 0%, #2d6a4f 50%, #4dac7a 100%)',
        }}>
            <div style={{
                background: '#fff', borderRadius: 20, padding: '48px 40px',
                width: '100%', maxWidth: 440, boxShadow: '0 24px 80px rgba(0,0,0,0.25)',
            }}>
                {/* Logo */}
                <div style={{ textAlign: 'center', marginBottom: 32 }}>
                    <div style={{
                        width: 64, height: 64, borderRadius: 16,
                        background: 'var(--color-primary)', display: 'inline-flex',
                        alignItems: 'center', justifyContent: 'center', fontSize: 32, marginBottom: 16,
                    }}>🌾</div>
                    <h1 style={{ fontSize: 26, fontWeight: 800, color: 'var(--text-primary)' }}>AgriMart Admin</h1>
                    <p style={{ color: 'var(--text-secondary)', marginTop: 4, fontSize: 14 }}>
                        Sign in to manage the AgriMart platform
                    </p>
                </div>

                <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                    <div className="input-group">
                        <label className="input-label">Admin Phone Number</label>
                        <input
                            className="input"
                            type="tel"
                            placeholder="+91 99999 99999"
                            value={form.phone}
                            onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
                            required
                        />
                    </div>
                    <div className="input-group">
                        <label className="input-label">Password</label>
                        <input
                            className="input"
                            type="password"
                            placeholder="Enter admin password"
                            value={form.password}
                            onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                            required
                        />
                    </div>
                    <button
                        type="submit"
                        disabled={loading}
                        className="btn btn-primary"
                        style={{ width: '100%', justifyContent: 'center', padding: '13px', fontSize: '16px', marginTop: 8 }}
                    >
                        {loading ? 'Signing in…' : '🔓 Sign In'}
                    </button>
                </form>

                <p style={{ textAlign: 'center', fontSize: 12, color: 'var(--text-tertiary)', marginTop: 24 }}>
                    AgriMart Admin Panel v1.0 · Secured Access
                </p>
            </div>
        </div>
    );
}
