const authService = require('../services/auth.service');
const { success, error } = require('../utils/apiResponse');

const sendOTP = async (req, res, next) => {
    try {
        const { phone, role } = req.body;
        if (!phone) return error(res, 'Phone number is required');
        const data = await authService.sendOTP(phone, role || 'FARMER');
        success(res, data, 'OTP sent to WhatsApp');
    } catch (err) { next(err); }
};

const verifyOTP = async (req, res, next) => {
    try {
        const { phone, otp, name, language, role } = req.body;
        if (!phone || !otp) return error(res, 'Phone and OTP are required');
        const data = await authService.verifyOTP({ phone, otp, name, language, role });
        success(res, data, 'Login successful');
    } catch (err) { next(err); }
};

const refreshToken = async (req, res, next) => {
    try {
        const { refreshToken: token } = req.body;
        if (!token) return error(res, 'Refresh token required');
        const data = await authService.refreshToken(token);
        success(res, data, 'Token refreshed');
    } catch (err) { next(err); }
};

const logout = async (req, res, next) => {
    try {
        await authService.logout(req.token);
        success(res, {}, 'Logged out successfully');
    } catch (err) { next(err); }
};

const me = async (req, res, next) => {
    try {
        success(res, { user: req.user });
    } catch (err) { next(err); }
};

const completeOnboarding = async (req, res, next) => {
    try {
        const data = await authService.completeOnboarding(req.user.id, req.user.role, req.body);
        success(res, data, 'Profile setup complete');
    } catch (err) { next(err); }
};

module.exports = { sendOTP, verifyOTP, refreshToken, logout, me, completeOnboarding };
