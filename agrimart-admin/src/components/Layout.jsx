import { Outlet, NavLink, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const NAV = [
    { to: '/dashboard', icon: '📊', label: 'Dashboard' },
    { to: '/users', icon: '👥', label: 'Users' },
    { to: '/suppliers', icon: '🏪', label: 'Suppliers' },
    { to: '/products', icon: '🌿', label: 'Products' },
    { to: '/orders', icon: '📦', label: 'Orders' },
    { to: '/mandi', icon: '📈', label: 'Mandi Prices' },
    { to: '/analytics', icon: '📊', label: 'Platform Analytics' },
    { to: '/schemes', icon: '🏛️', label: 'Govt Schemes' },
    { to: '/notifications', icon: '🔔', label: 'Notifications' },
    { to: '/settings', icon: '⚙️', label: 'Settings' },
];

const PAGE_TITLES = {
    '/dashboard': ['Dashboard', 'Overview & analytics'],
    '/users': ['Users', 'Manage farmers & suppliers'],
    '/suppliers': ['Suppliers', 'Verification & management'],
    '/products': ['Products', 'Approval & catalog management'],
    '/orders': ['Orders', 'All platform orders'],
    '/mandi': ['Mandi Prices', 'Live crop market prices'],
    '/analytics': ['Platform Analytics', 'Detailed platform performance metrics'],
    '/schemes': ['Govt Schemes', 'Manage government schemes'],
    '/notifications': ['Notifications', 'Push & WhatsApp broadcasts'],
    '/settings': ['Settings', 'Platform configuration & maintenance'],
};

export default function Layout() {
    const { admin, logout } = useAuth();
    const { pathname } = useLocation();
    const [title, subtitle] = PAGE_TITLES[pathname] || ['AgriMart', 'Admin Panel'];

    return (
        <div className="layout">
            <aside className="sidebar">
                <div className="sidebar-brand">
                    <div className="sidebar-brand-logo">
                        <div className="sidebar-brand-icon">🌾</div>
                        <div className="sidebar-brand-text">
                            <h1>AgriMart</h1>
                            <span>ADMIN PANEL</span>
                        </div>
                    </div>
                </div>

                <nav className="sidebar-nav">
                    <div className="sidebar-section-title">Main Menu</div>
                    {NAV.map(({ to, icon, label }) => (
                        <NavLink key={to} to={to} className={({ isActive }) => `sidebar-item${isActive ? ' active' : ''}`}>
                            <span className="sidebar-item-icon">{icon}</span>
                            <span>{label}</span>
                        </NavLink>
                    ))}
                </nav>

                <div className="sidebar-user">
                    <div className="sidebar-user-avatar">{admin?.name?.[0] || 'A'}</div>
                    <div className="sidebar-user-info">
                        <div className="sidebar-user-name">{admin?.name || 'Admin'}</div>
                        <div className="sidebar-user-role">Super Admin</div>
                    </div>
                    <button onClick={logout} title="Logout"
                        style={{ background: 'none', border: 'none', color: 'rgba(255,255,255,0.5)', cursor: 'pointer', fontSize: 18 }}>
                        ⏻
                    </button>
                </div>
            </aside>

            <div className="main-content">
                <header className="topbar">
                    <div className="topbar-left">
                        <h2>{title}</h2>
                        <p>{subtitle}</p>
                    </div>
                    <div className="topbar-right">
                        <div style={{ fontSize: 13, color: 'var(--text-secondary)' }}>
                            {new Date().toLocaleDateString('en-IN', { weekday: 'short', year: 'numeric', month: 'short', day: 'numeric' })}
                        </div>
                    </div>
                </header>
                <main className="page-content animate-fade">
                    <Outlet />
                </main>
            </div>
        </div>
    );
}
