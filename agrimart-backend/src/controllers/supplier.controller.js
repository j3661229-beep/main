const supplierService = require('../services/supplier.service');
const { success, paginated } = require('../utils/apiResponse');
const { getPagination } = require('../utils/helpers');

const getSupplierId = (req) => req.user?.supplier?.id;

const getProfile = async (req, res, next) => {
    try { success(res, await supplierService.getProfile(getSupplierId(req))); } catch (e) { next(e); }
};
const updateProfile = async (req, res, next) => {
    try { success(res, await supplierService.updateProfile(getSupplierId(req), req.body), 'Profile updated'); } catch (e) { next(e); }
};
const getDashboard = async (req, res, next) => {
    try { success(res, await supplierService.getDashboard(getSupplierId(req))); } catch (e) { next(e); }
};
const getOrders = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { orders, total } = await supplierService.getOrders(getSupplierId(req), pag, req.query);
        paginated(res, orders, pag.page, pag.limit, total);
    } catch (e) { next(e); }
};
const getOrder = async (req, res, next) => {
    try { success(res, await supplierService.getOrder(getSupplierId(req), req.params.id)); } catch (e) { next(e); }
};
const updateOrderStatus = async (req, res, next) => {
    try { success(res, await supplierService.updateOrderStatus(getSupplierId(req), req.params.id, req.body.status), 'Status updated'); } catch (e) { next(e); }
};
const getProducts = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { products, total } = await supplierService.getProducts(getSupplierId(req), pag);
        paginated(res, products, pag.page, pag.limit, total);
    } catch (e) { next(e); }
};
const getAnalytics = async (req, res, next) => {
    try { success(res, await supplierService.getAnalytics(getSupplierId(req))); } catch (e) { next(e); }
};

module.exports = { getProfile, updateProfile, getDashboard, getOrders, getOrder, updateOrderStatus, getProducts, getAnalytics };
