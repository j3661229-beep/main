import { useState } from 'react';
import toast from 'react-hot-toast';

export default function Settings() {
    const [loading, setLoading] = useState(false);
    const [config, setConfig] = useState({
        platformName: 'AgriMart',
        supportEmail: 'support@agrimart.com',
        supportPhone: '+91 800 123 4567',
        commissionRate: '5',
        minOrderValue: '500',
        maintenanceMode: false,
        enableAIFeatures: true,
        allowSupplierSelfRegistration: true
    });

    const handleSave = (e) => {
        e.preventDefault();
        setLoading(true);
        setTimeout(() => {
            toast.success('Settings updated successfully!');
            setLoading(false);
        }, 1000);
    };

    return (
        <div className="animate-fade">
            <h2 className="card-title mb-24" style={{ fontSize: 24 }}>⚙️ Platform Settings</h2>
            
            <form onSubmit={handleSave}>
                <div className="grid-2 gap-24">
                    {/* General Settings */}
                    <div className="card">
                        <div className="card-header bg-gray-50">
                            <span className="card-title">General Configuration</span>
                        </div>
                        <div className="card-body p-24">
                            <div className="input-group mb-16">
                                <label className="input-label">Platform Name</label>
                                <input 
                                    className="input" 
                                    value={config.platformName}
                                    onChange={e => setConfig({...config, platformName: e.target.value})}
                                />
                            </div>
                            <div className="input-group mb-16">
                                <label className="input-label">Support Email</label>
                                <input 
                                    className="input" 
                                    type="email"
                                    value={config.supportEmail}
                                    onChange={e => setConfig({...config, supportEmail: e.target.value})}
                                />
                            </div>
                            <div className="input-group mb-16">
                                <label className="input-label">Support Phone</label>
                                <input 
                                    className="input" 
                                    value={config.supportPhone}
                                    onChange={e => setConfig({...config, supportPhone: e.target.value})}
                                />
                            </div>
                        </div>
                    </div>

                    {/* Financial Settings */}
                    <div className="card">
                        <div className="card-header bg-gray-50">
                            <span className="card-title">Financial & Rules</span>
                        </div>
                        <div className="card-body p-24">
                            <div className="input-group mb-16">
                                <label className="input-label">Platform Commission (%)</label>
                                <input 
                                    className="input" 
                                    type="number"
                                    value={config.commissionRate}
                                    onChange={e => setConfig({...config, commissionRate: e.target.value})}
                                />
                            </div>
                            <div className="input-group mb-16">
                                <label className="input-label">Minimum Order Value (₹)</label>
                                <input 
                                    className="input" 
                                    type="number"
                                    value={config.minOrderValue}
                                    onChange={e => setConfig({...config, minOrderValue: e.target.value})}
                                />
                            </div>
                        </div>
                    </div>

                    {/* Feature Toggles */}
                    <div className="card">
                        <div className="card-header bg-gray-50">
                            <span className="card-title">Feature Toggles</span>
                        </div>
                        <div className="card-body p-24">
                            <div className="flex-between mb-16">
                                <div>
                                    <div style={{ fontWeight: 600 }}>Enable AI Features</div>
                                    <div className="text-xs text-secondary">Turn off Soil/Disease analysis globally</div>
                                </div>
                                <input 
                                    type="checkbox" 
                                    checked={config.enableAIFeatures}
                                    onChange={e => setConfig({...config, enableAIFeatures: e.target.checked})}
                                />
                            </div>
                            <div className="flex-between mb-16">
                                <div>
                                    <div style={{ fontWeight: 600 }}>Supplier Self-Registration</div>
                                    <div className="text-xs text-secondary">Allow new suppliers to apply themselves</div>
                                </div>
                                <input 
                                    type="checkbox" 
                                    checked={config.allowSupplierSelfRegistration}
                                    onChange={e => setConfig({...config, allowSupplierSelfRegistration: e.target.checked})}
                                />
                            </div>
                            <div className="flex-between">
                                <div>
                                    <div style={{ fontWeight: 600, color: 'var(--red-600)' }}>Maintenance Mode</div>
                                    <div className="text-xs text-secondary">Show maintenance screen to all users</div>
                                </div>
                                <input 
                                    type="checkbox" 
                                    checked={config.maintenanceMode}
                                    onChange={e => setConfig({...config, maintenanceMode: e.target.checked})}
                                />
                            </div>
                        </div>
                    </div>

                    {/* Admin Profile */}
                    <div className="card">
                        <div className="card-header bg-gray-50">
                            <span className="card-title">Admin Account</span>
                        </div>
                        <div className="card-body p-24 text-center">
                            <div className="avatar avatar-xl mb-16" style={{ width: 80, height: 80, fontSize: 32, margin: '0 auto 16px' }}>👑</div>
                            <div style={{ fontWeight: 700, fontSize: 18 }}>System Administrator</div>
                            <div className="text-sm text-secondary mb-16">+91 99999 99999</div>
                            <button className="btn btn-outline btn-sm" type="button" onClick={() => toast('Password reset link sent!')}>
                                🔑 Reset Password
                            </button>
                        </div>
                    </div>
                </div>

                <div className="flex-end mt-24">
                    <button className="btn btn-primary btn-lg" type="submit" disabled={loading}>
                        {loading ? <><span className="btn-spinner" /> Saving...</> : '💾 Save All Settings'}
                    </button>
                </div>
            </form>
        </div>
    );
}
