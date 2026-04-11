import { createContext, useContext, useState, useEffect } from 'react';
import { adminLogin as apiLogin } from '../lib/api';

export const AuthContext = createContext(null);

export function AuthProvider({ children }) {
    const [admin, setAdmin] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const token = localStorage.getItem('admin_token');
        const stored = localStorage.getItem('admin_user');
        if (token && stored) {
            try { setAdmin(JSON.parse(stored)); } catch { /* ignore bad data */ }
        }
        setLoading(false);
    }, []);

    const login = async (phone, password) => {
        const res = await apiLogin({ phone, password });
        // Interceptor already unwraps axios res.data, so `res` IS the backend JSON body:
        // { success: true, message: '...', data: { token, user } }
        const { token, user } = res.data || res;
        if (!token) throw new Error('Login failed — no token received');
        localStorage.setItem('admin_token', token);
        localStorage.setItem('admin_user', JSON.stringify(user));
        setAdmin(user);
        return res;
    };

    const logout = () => {
        localStorage.removeItem('admin_token');
        localStorage.removeItem('admin_user');
        setAdmin(null);
    };

    return (
        <AuthContext.Provider value={{ admin, login, logout, loading }}>
            {children}
        </AuthContext.Provider>
    );
}
