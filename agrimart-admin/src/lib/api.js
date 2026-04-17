import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_URL || 'http://10.10.56.253:3000/api';

const api = axios.create({
    baseURL: BASE_URL,
    timeout: 15000,
    headers: { 'Content-Type': 'application/json' },
});

api.interceptors.request.use((config) => {
    const token = localStorage.getItem('admin_token');
    if (token) config.headers.Authorization = `Bearer ${token}`;
    return config;
});

api.interceptors.response.use(
    (res) => res.data,
    (err) => {
        if (err.response?.status === 401) {
            localStorage.removeItem('admin_token');
            localStorage.removeItem('admin_user');
            // PrivateRoute will handle redirect to /login
            if (!window.location.pathname.includes('/login')) {
                window.location.href = '/login';
            }
        }
        return Promise.reject(err.response?.data || err);
    }
);

/* Auth */
export const adminLogin = (data) => api.post('/admin/login', data);

/* Dashboard */
export const getDashboard = () => api.get('/admin/dashboard');

/* Users */
export const getUsers = (params) => api.get('/admin/users', { params });
export const getUser = (id) => api.get(`/admin/users/${id}`);
export const toggleUser = (id) => api.patch(`/admin/users/${id}/toggle`);

/* Suppliers */
export const getPendingSuppliers = () => api.get('/admin/suppliers/pending');
export const getAllSuppliers = (params) => api.get('/admin/suppliers', { params });
export const verifySupplier = (id, data) => api.post(`/admin/suppliers/${id}/verify`, data);

/* Dealers */
export const getPendingDealers = () => api.get('/admin/dealers/pending');
export const getAllDealers = (params) => api.get('/admin/dealers', { params });
export const verifyDealer = (id, data) => api.post(`/admin/dealers/${id}/verify`, data);


/* Products */
export const getProducts = (params) => api.get('/admin/products', { params });
export const approveProduct = (id) => api.patch(`/admin/products/${id}/approve`);
export const rejectProduct = (id) => api.patch(`/admin/products/${id}/reject`);

/* Orders */
export const getOrders = (params) => api.get('/admin/orders', { params });

/* Schemes */
export const createScheme = (data) => api.post('/admin/schemes', data);
export const updateScheme = (id, data) => api.put(`/admin/schemes/${id}`, data);
export const deleteScheme = (id) => api.delete(`/admin/schemes/${id}`);

/* Notifications */
export const broadcastNotification = (data) => api.post('/admin/notifications/broadcast', data);

/* Mandi */
export const getMandiPrices = (params) => api.get('/mandi/prices', { params });

export default api;
