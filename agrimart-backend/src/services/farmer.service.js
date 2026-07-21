const prisma = require('../config/database');
const axios = require('axios');
const redis = require('../config/redis');
const cache = require('../utils/cache');
const { assessFarmerProfile } = require('../utils/farmerProfile.util');

const DASHBOARD_CACHE_TTL = 120;

const getProfile = async (farmerId) => {
    return prisma.farmer.findUnique({ where: { id: farmerId }, include: { user: true } });
};

const updateProfile = async (farmerId, data) => {
    const { name, language, profilePhoto } = data;
    const farmer = await prisma.farmer.findUnique({ where: { id: farmerId } });
    await prisma.user.update({ where: { id: farmer.userId }, data: { name, language, profilePhoto } });
    return prisma.farmer.findUnique({ where: { id: farmerId }, include: { user: true } });
};

const updateFarmDetails = async (farmerId, data) => {
    const waterSource = data.irrigationType && data.waterSource
        ? `${data.waterSource} (${data.irrigationType})`
        : data.waterSource;

    const updated = await prisma.farmer.update({
        where: { id: farmerId },
        data: {
            village: data.village,
            taluka: data.taluka,
            district: data.district,
            state: data.state,
            pincode: data.pincode,
            latitude: data.latitude != null ? parseFloat(data.latitude) : undefined,
            longitude: data.longitude != null ? parseFloat(data.longitude) : undefined,
            farmSizeAcres: data.farmSizeAcres != null ? parseFloat(data.farmSizeAcres) : undefined,
            soilType: data.soilType,
            waterSource,
            currentCrops: data.currentCrops,
            bankAccountNo: data.bankAccountNo,
            ifscCode: data.ifscCode,
        },
        include: { user: true },
    });

    await cache.del(`farmer:dashboard:${farmerId}`);
    return updated;
};

const getFarmSetupStatus = async (farmerId) => {
    const farmer = await prisma.farmer.findUnique({
        where: { id: farmerId },
        include: { user: { select: { name: true, language: true } } },
    });
    if (!farmer) throw Object.assign(new Error('Farmer not found'), { statusCode: 404 });
    return { farmer, ...assessFarmerProfile(farmer) };
};

const getDashboard = async (farmerId) => {
    const cacheKey = `farmer:dashboard:${farmerId}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const farmer = await prisma.farmer.findUnique({ where: { id: farmerId }, include: { user: true } });

    // Weather + price alerts only (v1 farmer app — no marketplace on dashboard)
    const weatherPromise = (async () => {
        if (farmer.latitude == null || farmer.longitude == null) return null;
        const wKey = `weather:${farmer.latitude.toFixed(2)},${farmer.longitude.toFixed(2)}`;
        const cachedW = await redis.get(wKey);
        if (cachedW) return typeof cachedW === 'string' ? JSON.parse(cachedW) : cachedW;
        if (process.env.OPENWEATHER_API_KEY) {
            try {
                const base = process.env.OPENWEATHER_BASE_URL || 'https://api.openweathermap.org/data/2.5';
                const resp = await axios.get(`${base}/weather`, {
                    params: { lat: farmer.latitude, lon: farmer.longitude, appid: process.env.OPENWEATHER_API_KEY, units: 'metric' },
                    timeout: 8000,
                });
                redis.setWithExpiry(wKey, 1800, JSON.stringify(resp.data)).catch(() => {});
                return resp.data;
            } catch (e) { return null; }
        }
        return null;
    })();

    const priceAlertsPromise = prisma.priceAlert.findMany({
        where: { farmerId, isActive: true },
        take: 5,
        select: { id: true, cropName: true, targetPrice: true, isActive: true },
    });

    const [weather, priceAlerts] = await Promise.all([weatherPromise, priceAlertsPromise]);

    const result = { farmer, weather, priceAlerts };
    await cache.set(cacheKey, result, DASHBOARD_CACHE_TTL);
    return result;
};

const getOrders = async (farmerId, { page, limit, skip }) => {
    const [orders, total] = await Promise.all([
        prisma.order.findMany({
            where: { farmerId },
            skip, take: limit,
            orderBy: { createdAt: 'desc' },
            include: { items: { include: { product: { select: { id: true, name: true, price: true, images: true, unit: true } }, supplier: { select: { id: true, businessName: true, user: { select: { name: true } } } } } }, payment: true },
        }),
        prisma.order.count({ where: { farmerId } }),
    ]);
    return { orders, total };
};

const getOrder = async (farmerId, orderId) => {
    const order = await prisma.order.findFirst({
        where: { id: orderId, farmerId },
        include: { items: { include: { product: true, supplier: { include: { user: true } }, review: true } }, payment: true },
    });
    if (!order) throw Object.assign(new Error('Order not found'), { statusCode: 404 });
    return order;
};

const createPriceAlert = async (farmerId, { cropName, targetPrice }) => {
    return prisma.priceAlert.create({ data: { farmerId, cropName, targetPrice: parseFloat(targetPrice) } });
};

const getPriceAlerts = async (farmerId) => {
    return prisma.priceAlert.findMany({ where: { farmerId }, orderBy: { createdAt: 'desc' } });
};

const deletePriceAlert = async (farmerId, alertId) => {
    const alert = await prisma.priceAlert.findFirst({ where: { id: alertId, farmerId } });
    if (!alert) throw Object.assign(new Error('Alert not found'), { statusCode: 404 });
    return prisma.priceAlert.delete({ where: { id: alertId } });
};

const getSoilReports = async (farmerId) => {
    return prisma.soilReport.findMany({ where: { farmerId }, orderBy: { createdAt: 'desc' } });
};

const getSoilReport = async (farmerId, reportId) => {
    const report = await prisma.soilReport.findFirst({ where: { id: reportId, farmerId } });
    if (!report) throw Object.assign(new Error('Soil report not found'), { statusCode: 404 });
    return report;
};

const submitFpoInterest = async (farmerId, { cropName, approxQuintals, district, village }) => {
    const farmer = await prisma.farmer.findUnique({ where: { id: farmerId }, include: { user: true } });
    if (!farmer) throw Object.assign(new Error('Farmer not found'), { statusCode: 404 });

    await prisma.notification.create({
        data: {
            userId: farmer.userId,
            title: 'FPO bulk interest registered',
            body: `We'll notify you when FPO pooling opens for ${cropName} in ${district || farmer.district}.`,
            type: 'FPO_INTEREST',
            data: { cropName, approxQuintals, district: district || farmer.district, village },
        },
    });

    return { cropName, approxQuintals, district: district || farmer.district };
};

module.exports = {
    getProfile, updateProfile, updateFarmDetails, getFarmSetupStatus, getDashboard,
    getOrders, getOrder, createPriceAlert, getPriceAlerts, deletePriceAlert,
    getSoilReports, getSoilReport, submitFpoInterest,
};
