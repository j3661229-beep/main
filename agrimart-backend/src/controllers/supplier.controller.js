const supplierService = require('../services/supplier.service');
const { success, paginated } = require('../utils/apiResponse');
const { getPagination } = require('../utils/helpers');
const prisma = require('../config/database');

const getUserId = (req) => req.user?.id;

// Resolve the supplier's internal UUID from the authenticated request.
// Auth middleware already joins `supplier` onto `req.user`, so we use that first.
// Falls back to a DB lookup by userId in case the join is missing.
const resolveSupplier = async (req) => {
    const directId = req.user?.supplier?.id;
    if (directId) return directId;
    const s = await prisma.supplier.findUnique({ where: { userId: getUserId(req) } });
    if (!s) throw Object.assign(new Error('Supplier profile not found. Please complete onboarding.'), { statusCode: 404 });
    return s.id;
};

const getProfile = async (req, res, next) => {
    try { success(res, await supplierService.getProfile(await resolveSupplier(req))); } catch (e) { next(e); }
};
const updateProfile = async (req, res, next) => {
    try { success(res, await supplierService.updateProfile(await resolveSupplier(req), req.body), 'Profile updated'); } catch (e) { next(e); }
};
const getDashboard = async (req, res, next) => {
    try { success(res, await supplierService.getDashboard(await resolveSupplier(req))); } catch (e) { next(e); }
};
const getOrders = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { orders, total } = await supplierService.getOrders(await resolveSupplier(req), pag, req.query);
        paginated(res, orders, pag.page, pag.limit, total);
    } catch (e) { next(e); }
};
const getOrder = async (req, res, next) => {
    try { success(res, await supplierService.getOrder(await resolveSupplier(req), req.params.id)); } catch (e) { next(e); }
};
const updateOrderStatus = async (req, res, next) => {
    try { success(res, await supplierService.updateOrderStatus(await resolveSupplier(req), req.params.id, req.body.status), 'Status updated'); } catch (e) { next(e); }
};
const getProducts = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { products, total } = await supplierService.getProducts(await resolveSupplier(req), pag);
        paginated(res, products, pag.page, pag.limit, total);
    } catch (e) { next(e); }
};
const getAnalytics = async (req, res, next) => {
    try { success(res, await supplierService.getAnalytics(await resolveSupplier(req))); } catch (e) { next(e); }
};

module.exports = { getProfile, updateProfile, getDashboard, getOrders, getOrder, updateOrderStatus, getProducts, getAnalytics };
