const prisma = require('../config/database');
const axios = require('axios');
const redis = require('../config/redis');

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
    return prisma.farmer.update({
        where: { id: farmerId },
        data: {
            village: data.village,
            taluka: data.taluka,
            district: data.district,
            pincode: data.pincode,
            latitude: data.latitude ? parseFloat(data.latitude) : undefined,
            longitude: data.longitude ? parseFloat(data.longitude) : undefined,
            farmSizeAcres: data.farmSizeAcres ? parseFloat(data.farmSizeAcres) : undefined,
            soilType: data.soilType,
            waterSource: data.waterSource,
            currentCrops: data.currentCrops,
            bankAccountNo: data.bankAccountNo,
            ifscCode: data.ifscCode,
        },
        include: { user: true },
    });
};

const getDashboard = async (farmerId) => {
    const farmer = await prisma.farmer.findUnique({ where: { id: farmerId }, include: { user: true } });

    // Weather Promise
    const weatherPromise = (async () => {
        if (!farmer.latitude || !farmer.longitude) return null;
        const cacheKey = `weather:${farmer.latitude.toFixed(2)},${farmer.longitude.toFixed(2)}`;
        const cached = await redis.get(cacheKey);
        if (cached) return JSON.parse(cached);
        if (process.env.OPENWEATHER_API_KEY) {
            try {
                const resp = await axios.get(`${process.env.OPENWEATHER_BASE_URL}/weather`, {
                    params: { lat: farmer.latitude, lon: farmer.longitude, appid: process.env.OPENWEATHER_API_KEY, units: 'metric' },
                });
                await redis.setWithExpiry(cacheKey, 1800, JSON.stringify(resp.data));
                return resp.data;
            } catch (e) { return null; }
        }
        return null;
    })();

    // Nearby products Promise — lean select
    const nearbyProductsPromise = prisma.product.findMany({
        where: { isActive: true, isApproved: true, stockQuantity: { gt: 0 } },
        take: 6,
        select: {
            id: true, name: true, price: true, unit: true, images: true, isOrganic: true, brand: true,
            supplier: { select: { id: true, businessName: true, district: true, user: { select: { name: true } } } },
        },
        orderBy: { createdAt: 'desc' },
    });

    const recentOrdersPromise = prisma.order.findMany({
        where: { farmerId },
        take: 5,
        orderBy: { createdAt: 'desc' },
        include: { items: { include: { product: true } } },
    });

    const priceAlertsPromise = prisma.priceAlert.findMany({ where: { farmerId, isActive: true }, take: 5 });

    // Execute in parallel (Fastest Response Time)
    const [weather, nearbyProducts, recentOrders, priceAlerts] = await Promise.all([
        weatherPromise,
        nearbyProductsPromise,
        recentOrdersPromise,
        priceAlertsPromise
    ]);

    return { farmer, weather, nearbyProducts, recentOrders, priceAlerts };
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

module.exports = { getProfile, updateProfile, updateFarmDetails, getDashboard, getOrders, getOrder, createPriceAlert, getPriceAlerts, deletePriceAlert, getSoilReports, getSoilReport };
