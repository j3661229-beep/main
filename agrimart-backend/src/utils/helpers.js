/**
 * Calculate distance between two lat/lng points (Haversine formula)
 * Returns distance in km
 */const haversineDistance = (lat1, lng1, lat2, lng2) => {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLng = ((lng2 - lng1) * Math.PI) / 180;
    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
};

/**
 * Generate a 6-digit OTP
 */
const DEV_OTP = '123456';

/** When true, OTP is always 123456 and rate limits are relaxed. Set STATIC_OTP=false in production. */
const useStaticOtp = () => process.env.STATIC_OTP !== 'false';

const generateOTP = () => {
    if (useStaticOtp()) return DEV_OTP;
    return String(Math.floor(100000 + Math.random() * 900000));
};

/**
 * Format phone number to E.164
 */
const formatPhone = (phone) => {
    const digits = phone.replace(/\D/g, '');
    if (digits.startsWith('91') && digits.length === 12) return `+${digits}`;
    if (digits.length === 10) return `+91${digits}`;
    return `+${digits}`;
};

/**
 * Paginate query
 */
const getPagination = (query) => {
    const page = Math.max(1, parseInt(query.page) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(query.limit) || 20));
    const skip = (page - 1) * limit;
    return { page, limit, skip };
};

/**
 * Generate order ID prefix
 */
const generateOrderId = () => {
    const ts = Date.now().toString(36).toUpperCase();
    const rand = Math.random().toString(36).substring(2, 6).toUpperCase();
    return `AGM-${ts}${rand}`;
};

module.exports = {
    haversineDistance,
    generateOTP,
    useStaticOtp,
    DEV_OTP,
    formatPhone,
    getPagination,
    generateOrderId,
};
