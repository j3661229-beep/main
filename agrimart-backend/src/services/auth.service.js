const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const prisma = require('../config/database');
const redis = require('../config/redis');
const { generateOTP, formatPhone, useStaticOtp, DEV_OTP } = require('../utils/helpers');
const logger = require('../utils/logger');

let twilioClient;
if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
    const twilio = require('twilio');
    twilioClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
}

const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret_change_in_production';
const JWT_EXPIRES = process.env.JWT_EXPIRES_IN || '7d';
const USER_CACHE_TTL = 300; // 5 minutes

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

    await redis.setWithExpiry(otpKey, 600, otp);       // 10 min TTL
    await redis.setWithExpiry(roleKey, 600, role);

    await sendWhatsAppOTP(formatted, otp);

    const result = { phone: formatted };
    if (useStaticOtp()) {
        result.otp = DEV_OTP;
        logger.warn(`[STATIC OTP] Use OTP ${DEV_OTP} for ${formatted}`);
    }
    return result;
};

// Cache user profile in Redis
const cacheUser = async (user) => {
    try {
        await redis.setWithExpiry(`user:${user.id}`, USER_CACHE_TTL, JSON.stringify(user));
    } catch (e) {
        logger.warn(`Failed to cache user ${user.id}: ${e.message}`);
    }
};

const invalidateUserCache = async (userId) => {
    try {
        await redis.del(`user:${userId}`);
    } catch (e) {
        logger.warn(`Failed to invalidate user cache ${userId}: ${e.message}`);
    }
};

const verifyOTP = async ({ phone, otp, name, language, role }) => {
    const formatted = formatPhone(phone);
    const otpKey = `otp:${formatted}`;
    const rolesKey = `otp_role:${formatted}`;

    const storedOTP = await redis.get(otpKey);
    const staticOk = useStaticOtp() && otp === DEV_OTP;
    if (!staticOk && (!storedOTP || storedOTP !== otp)) {
        throw Object.assign(new Error('Invalid or expired OTP'), { statusCode: 400 });
    }
    if (storedOTP) await redis.del(otpKey, rolesKey);

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
                    userId: user.id, village: '', taluka: '', district: 'Nashik', pincode: '', farmSizeAcres: 0,
                },
            });
        } else if (user.role === 'SUPPLIER') {
            await prisma.supplier.create({
                data: {
                    userId: user.id, businessName: 'My Store', gstNumber: null, address: '', district: 'Nashik', pincode: '',
                    docStatus: 'PENDING',
                },
            });
        } else if (user.role === 'DEALER') {
            await prisma.dealer.create({
                data: {
                    userId: user.id, businessName: 'My Agency', address: '', district: 'Nashik', pincode: '',
                    docStatus: 'PENDING',
                },
            });
        }
    } else if (name) {
        user = await prisma.user.update({ where: { id: user.id }, data: { name, language: language || user.language } });
    }

    // Check if SUPPLIER/DEALER account is pending document verification
    if (user.role === 'SUPPLIER') {
        const supplier = await prisma.supplier.findUnique({ where: { userId: user.id } });
        if (supplier && supplier.docStatus === 'PENDING' && supplier.govtDocUrl) {
            const { token, refreshToken } = generateTokens(user.id, user.role);
            const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
            await prisma.session.create({ data: { userId: user.id, token, expiresAt } });
            const fullUser = await prisma.user.findUnique({
                where: { id: user.id }, include: { farmer: true, supplier: true, dealer: true },
            });
            return { user: fullUser, token, refreshToken, pendingVerification: true };
        }
        if (supplier && supplier.docStatus === 'REJECTED') {
            throw Object.assign(new Error(`Your verification was rejected: ${supplier.rejectedReason || 'Contact support'}`), { statusCode: 403 });
        }
    } else if (user.role === 'DEALER') {
        const dealer = await prisma.dealer.findUnique({ where: { userId: user.id } });
        if (dealer && dealer.docStatus === 'PENDING' && dealer.govtDocUrl) {
            const { token, refreshToken } = generateTokens(user.id, user.role);
            const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
            await prisma.session.create({ data: { userId: user.id, token, expiresAt } });
            const fullUser = await prisma.user.findUnique({
                where: { id: user.id }, include: { farmer: true, supplier: true, dealer: true },
            });
            return { user: fullUser, token, refreshToken, pendingVerification: true };
        }
        if (dealer && dealer.docStatus === 'REJECTED') {
            throw Object.assign(new Error(`Your verification was rejected: ${dealer.rejectedReason || 'Contact support'}`), { statusCode: 403 });
        }
    }

    const { token, refreshToken } = generateTokens(user.id, user.role);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await prisma.session.create({ data: { userId: user.id, token, expiresAt } });

    const fullUser = await prisma.user.findUnique({
        where: { id: user.id }, include: { farmer: true, supplier: true, dealer: true },
    });

    await cacheUser(fullUser);
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
        data: { isVerified: role === 'FARMER', name: data.name },
    });

    if (role === 'FARMER') {
        await prisma.farmer.update({
            where: { userId },
            data: {
                village: data.village || '',
                district: data.district || '',
                state: data.state || 'Maharashtra',
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
                state: data.state || 'Maharashtra',
                isVerified: false, // Requires admin doc approval
                docStatus: 'PENDING',
            }
        });
    } else if (role === 'DEALER') {
        await prisma.dealer.update({
            where: { userId },
            data: {
                businessName: data.businessName || '',
                address: data.address || '',
                district: data.district || '',
                state: data.state || 'Maharashtra',
                isVerified: false, // Requires admin doc approval
                docStatus: 'PENDING',
            }
        });
    }

    await invalidateUserCache(userId);

    return prisma.user.findUnique({
        where: { id: userId }, include: { farmer: true, supplier: true, dealer: true },
    });
};

const googleSignIn = async ({ email, googleId, name, photoUrl, role }) => {
    let user = await prisma.user.findFirst({
        where: {
            OR: [
                { googleId },
                { email }
            ]
        }
    });

    if (user && user.role !== role) {
        throw Object.assign(new Error(`This account is registered as a ${user.role}. Cannot login as ${role}.`), { statusCode: 403 });
    }

    if (!user) {
        user = await prisma.user.create({
            data: {
                email,
                googleId,
                name: name || 'AgriMart User',
                profilePhoto: photoUrl,
                role: role || 'FARMER',
                language: 'marathi',
                isVerified: false
            },
        });
        if (user.role === 'FARMER') {
            await prisma.farmer.create({
                data: {
                    userId: user.id, village: '', taluka: '', district: 'Nashik', pincode: '', farmSizeAcres: 0,
                },
            });
        } else if (user.role === 'SUPPLIER') {
            await prisma.supplier.create({
                data: {
                    userId: user.id, businessName: 'My Store', gstNumber: null, address: '', district: 'Nashik', pincode: '',
                    docStatus: 'PENDING',
                },
            });
        } else if (user.role === 'DEALER') {
            await prisma.dealer.create({
                data: {
                    userId: user.id, businessName: name, address: '', district: 'Nashik', pincode: '',
                    docStatus: 'PENDING',
                },
            });
        }
    } else {
        user = await prisma.user.update({
            where: { id: user.id },
            data: {
                googleId: user.googleId || googleId,
                profilePhoto: user.profilePhoto || photoUrl,
                name: user.name === 'AgriMart User' && name ? name : user.name
            }
        });
        // Fix legacy profiles that stored state name as district
        if (user.role === 'FARMER') {
            const farmer = await prisma.farmer.findUnique({ where: { userId: user.id } });
            if (farmer && (farmer.district === 'Maharashtra' || farmer.district === farmer.state)) {
                await prisma.farmer.update({ where: { userId: user.id }, data: { district: 'Nashik' } });
            }
        }
    }

    // Check pending verification for SUPPLIER/DEALER
    let pendingVerification = false;
    if (user.role === 'SUPPLIER') {
        const supplier = await prisma.supplier.findUnique({ where: { userId: user.id } });
        if (supplier?.docStatus === 'PENDING' && supplier?.govtDocUrl) pendingVerification = true;
        if (supplier?.docStatus === 'REJECTED') {
            throw Object.assign(new Error(`Your verification was rejected: ${supplier.rejectedReason || 'Contact support'}`), { statusCode: 403 });
        }
    } else if (user.role === 'DEALER') {
        const dealer = await prisma.dealer.findUnique({ where: { userId: user.id } });
        if (dealer?.docStatus === 'PENDING' && dealer?.govtDocUrl) pendingVerification = true;
        if (dealer?.docStatus === 'REJECTED') {
            throw Object.assign(new Error(`Your verification was rejected: ${dealer.rejectedReason || 'Contact support'}`), { statusCode: 403 });
        }
    }

    const { token, refreshToken } = generateTokens(user.id, user.role);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await prisma.session.create({ data: { userId: user.id, token, expiresAt } });

    const fullUser = await prisma.user.findUnique({
        where: { id: user.id }, include: { farmer: true, supplier: true, dealer: true },
    });
    await cacheUser(fullUser);
    return { user: fullUser, token, refreshToken, pendingVerification };
};

const logout = async (token, userId) => {
    await prisma.session.deleteMany({ where: { token } });
    if (userId) await invalidateUserCache(userId);
};

const findUserByEmailOrPhone = async (emailOrPhone) => {
    const raw = String(emailOrPhone || '').trim();
    if (!raw) return null;
    if (raw.includes('@')) {
        return prisma.user.findUnique({
            where: { email: raw.toLowerCase() },
            include: { farmer: true, supplier: true, dealer: true },
        });
    }
    const formatted = formatPhone(raw);
    return prisma.user.findFirst({
        where: { OR: [{ phone: formatted }, { phone: raw }] },
        include: { farmer: true, supplier: true, dealer: true },
    });
};

const assertRoleAccess = async (user) => {
    if (user.role === 'SUPPLIER') {
        const supplier = user.supplier || await prisma.supplier.findUnique({ where: { userId: user.id } });
        if (supplier?.docStatus === 'REJECTED') {
            throw Object.assign(new Error(`Your verification was rejected: ${supplier.rejectedReason || 'Contact support'}`), { statusCode: 403 });
        }
        if (supplier?.docStatus === 'PENDING' && supplier?.govtDocUrl) {
            return { pendingVerification: true };
        }
    } else if (user.role === 'DEALER') {
        const dealer = user.dealer || await prisma.dealer.findUnique({ where: { userId: user.id } });
        if (dealer?.docStatus === 'REJECTED') {
            throw Object.assign(new Error(`Your verification was rejected: ${dealer.rejectedReason || 'Contact support'}`), { statusCode: 403 });
        }
        if (dealer?.docStatus === 'PENDING' && dealer?.govtDocUrl) {
            return { pendingVerification: true };
        }
    }
    return { pendingVerification: false };
};

const issueAuthSession = async (user, { pendingVerification = false } = {}) => {
    const { token, refreshToken } = generateTokens(user.id, user.role);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await prisma.session.create({ data: { userId: user.id, token, expiresAt } });

    const fullUser = await prisma.user.findUnique({
        where: { id: user.id },
        include: { farmer: true, supplier: true, dealer: true },
    });
    await cacheUser(fullUser);
    return { user: fullUser, token, refreshToken, pendingVerification };
};

const loginWithPassword = async ({ emailOrPhone, password, role }) => {
    if (!emailOrPhone || !password) {
        throw Object.assign(new Error('Email/phone and password are required'), { statusCode: 400 });
    }

    const user = await findUserByEmailOrPhone(emailOrPhone);
    if (!user || !user.passwordHash) {
        throw Object.assign(new Error('Invalid email/phone or password'), { statusCode: 401 });
    }
    if (!user.isActive) {
        throw Object.assign(new Error('Account is inactive'), { statusCode: 403 });
    }
    if (role && user.role !== role) {
        throw Object.assign(new Error(`This account is registered as a ${user.role}. Cannot login as ${role}.`), { statusCode: 403 });
    }
    if (!bcrypt.compareSync(password, user.passwordHash)) {
        throw Object.assign(new Error('Invalid email/phone or password'), { statusCode: 401 });
    }

    const access = await assertRoleAccess(user);
    return issueAuthSession(user, access);
};

module.exports = { sendOTP, verifyOTP, googleSignIn, refreshToken, completeOnboarding, logout, invalidateUserCache, loginWithPassword };
