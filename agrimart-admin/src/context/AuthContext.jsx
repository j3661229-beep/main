import { createContext, useContext, useState, useEffect } from 'react';
import { adminLogin as apiLogin } from '../lib/api';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
    const [admin, setAdmin] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const token = localStorage.getItem('admin_token');
        const stored = localStorage.getItem('admin_user');
        if (token && stored) {
            setAdmin(JSON.parse(stored));
        }
        setLoading(false);
    }, []);

    const login = async (phone, password) => {
        const res = await apiLogin({ phone, password });
        localStorage.setItem('admin_token', res.data.token);
        localStorage.setItem('admin_user', JSON.stringify(res.data.user));
        setAdmin(res.data.user);
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
};

export const useAuth = () => useContext(AuthContext);
