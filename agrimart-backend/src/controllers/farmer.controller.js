const farmerService = require('../services/farmer.service');
const { success, error, paginated } = require('../utils/apiResponse');
const { getPagination } = require('../utils/helpers');
const prisma = require('../config/database');

const getUserId = (req) => req.user?.id;

// Resolve farmer's internal UUID — prefers the joined row, falls back to DB lookup.
const resolveFarmer = async (req) => {
    const directId = req.user?.farmer?.id;
    if (directId) return directId;
    const f = await prisma.farmer.findUnique({ where: { userId: getUserId(req) } });
    if (!f) throw Object.assign(new Error('Farmer profile not found. Please complete onboarding.'), { statusCode: 404 });
    return f.id;
};

const getProfile = async (req, res, next) => {
    try {
        const data = await farmerService.getProfile(await resolveFarmer(req));
        success(res, data);
    } catch (err) { next(err); }
};

const updateProfile = async (req, res, next) => {
    try {
        const data = await farmerService.updateProfile(await resolveFarmer(req), req.body);
        success(res, data, 'Profile updated');
    } catch (err) { next(err); }
};

const updateFarmDetails = async (req, res, next) => {
    try {
        const data = await farmerService.updateFarmDetails(await resolveFarmer(req), req.body);
        success(res, data, 'Farm details updated');
    } catch (err) { next(err); }
};

const getDashboard = async (req, res, next) => {
    try {
        const data = await farmerService.getDashboard(await resolveFarmer(req));
        success(res, data);
    } catch (err) { next(err); }
};

const getOrders = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { orders, total } = await farmerService.getOrders(await resolveFarmer(req), pag);
        paginated(res, orders, pag.page, pag.limit, total);
    } catch (err) { next(err); }
};

const getOrder = async (req, res, next) => {
    try {
        const data = await farmerService.getOrder(await resolveFarmer(req), req.params.id);
        success(res, data);
    } catch (err) { next(err); }
};

const createPriceAlert = async (req, res, next) => {
    try {
        const data = await farmerService.createPriceAlert(await resolveFarmer(req), req.body);
        success(res, data, 'Price alert created', 201);
    } catch (err) { next(err); }
};

const getPriceAlerts = async (req, res, next) => {
    try {
        const data = await farmerService.getPriceAlerts(await resolveFarmer(req));
        success(res, data);
    } catch (err) { next(err); }
};

const deletePriceAlert = async (req, res, next) => {
    try {
        await farmerService.deletePriceAlert(await resolveFarmer(req), req.params.id);
        success(res, {}, 'Alert deleted');
    } catch (err) { next(err); }
};

const getSoilReports = async (req, res, next) => {
    try {
        const data = await farmerService.getSoilReports(await resolveFarmer(req));
        success(res, data);
    } catch (err) { next(err); }
};

const getSoilReport = async (req, res, next) => {
    try {
        const data = await farmerService.getSoilReport(await resolveFarmer(req), req.params.id);
        success(res, data);
    } catch (err) { next(err); }
};

module.exports = { getProfile, updateProfile, updateFarmDetails, getDashboard, getOrders, getOrder, createPriceAlert, getPriceAlerts, deletePriceAlert, getSoilReports, getSoilReport };
