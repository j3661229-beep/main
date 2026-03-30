const jwt = require('jsonwebtoken');
const prisma = require('../config/database');
const redis = require('../config/redis');
const { generateOTP, formatPhone } = require('../utils/helpers');
const logger = require('../utils/logger');

let twilioClient;
if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
    const twilio = require('twilio');
    twilioClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
}

const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret_change_in_production';
const JWT_EXPIRES = process.env.JWT_EXPIRES_IN || '7d';

const sendWhatsAppOTP = async (phone, otp) => {
    if (process.env.NODE_ENV === 'development' || !twilioClient) {
        logger.warn(`[DEV ONLY] Bypassing WhatsApp message to save credits. OTP for ${phone}: ${otp}`);
        return;
    }
    await twilioClient.messages.create({
        from: process.env.TWILIO_WHATSAPP_FROM,
        to: `whatsapp:${phone}`,
        body: `🌾 AgriMart OTP: *${otp}*\nValid for 10 minutes.\nDo not share with anyone.`,
    });
};

const generateTokens = (userId, role) => {
    const token = jwt.sign({ userId, role }, JWT_SECRET, { expiresIn: JWT_EXPIRES });
    const refreshToken = jwt.sign({ userId, role, type: 'refresh' }, JWT_SECRET, { expiresIn: '30d' });
    return { token, refreshToken };
};

const sendOTP = async (phone, role) => {
    const formatted = formatPhone(phone);
    const otp = generateOTP();
    const otpKey = `otp:${formatted}`;
    const roleKey = `otp_role:${formatted}`;

    await redis.setex(otpKey, 600, otp);       // 10 min TTL
    await redis.setex(roleKey, 600, role);

    await sendWhatsAppOTP(formatted, otp);
    return { phone: formatted };
};

const verifyOTP = async ({ phone, otp, name, language, role }) => {
    const formatted = formatPhone(phone);
    const otpKey = `otp:${formatted}`;
    const rolesKey = `otp_role:${formatted}`;

    const storedOTP = await redis.get(otpKey);
    if (!storedOTP || storedOTP !== otp) {
        throw Object.assign(new Error('Invalid or expired OTP'), { statusCode: 400 });
    }
    await redis.del(otpKey, rolesKey);

    // Find or create user
    let user = await prisma.user.findUnique({ where: { phone: formatted } });
    if (user && user.role !== role) {
        throw Object.assign(new Error(`This number is registered as a ${user.role}. Cannot login as ${role}.`), { statusCode: 403 });
    }
    if (!user) {
        user = await prisma.user.create({
            data: { phone: formatted, name: name || 'AgriMart User', role: role || 'FARMER', language: language || 'marathi' },
        });
        if (user.role === 'FARMER') {
            await prisma.farmer.create({
                data: {
                    userId: user.id, village: '', taluka: '', district: 'Maharashtra', pincode: '', farmSizeAcres: 0,
                },
            });
        } else if (user.role === 'SUPPLIER') {
            await prisma.supplier.create({
                data: {
                    userId: user.id, businessName: 'My Store', gstNumber: null, address: '', district: 'Maharashtra', pincode: '',
                },
            });
        }
    } else if (name) {
        user = await prisma.user.update({ where: { id: user.id }, data: { name, language: language || user.language } });
    }

    const { token, refreshToken } = generateTokens(user.id, user.role);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await prisma.session.create({ data: { userId: user.id, token, expiresAt } });

    const fullUser = await prisma.user.findUnique({
        where: { id: user.id }, include: { farmer: true, supplier: true },
    });
    return { user: fullUser, token, refreshToken };
};

const refreshToken = async (token) => {
    const decoded = jwt.verify(token, JWT_SECRET);
    if (decoded.type !== 'refresh') throw new Error('Invalid refresh token');

    const user = await prisma.user.findUnique({ where: { id: decoded.userId } });
    if (!user || !user.isActive) throw Object.assign(new Error('Account not found'), { statusCode: 401 });

    const { token: newToken, refreshToken: newRefresh } = generateTokens(user.id, user.role);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await prisma.session.create({ data: { userId: user.id, token: newToken, expiresAt } });
    return { token: newToken, refreshToken: newRefresh };
};

const completeOnboarding = async (userId, role, data) => {
    await prisma.user.update({
        where: { id: userId },
        data: { isVerified: true, name: data.name },
    });

    if (role === 'FARMER') {
        await prisma.farmer.update({
            where: { userId },
            data: {
                village: data.village || '',
                district: data.district || '',
                farmSizeAcres: data.farmSizeAcres != null ? parseFloat(data.farmSizeAcres) : 0,
            }
        });
    } else if (role === 'SUPPLIER') {
        await prisma.supplier.update({
            where: { userId },
            data: {
                businessName: data.businessName || '',
                address: data.address || '',
                district: data.district || '',
                isVerified: true
            }
        });
    }

    return prisma.user.findUnique({
        where: { id: userId }, include: { farmer: true, supplier: true },
    });
};

const logout = async (token) => {
    await prisma.session.deleteMany({ where: { token } });
};

module.exports = { sendOTP, verifyOTP, refreshToken, completeOnboarding, logout };
