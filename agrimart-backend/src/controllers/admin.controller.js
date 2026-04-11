const adminService = require('../services/admin.service');
const { success, created, paginated } = require('../utils/apiResponse');
const { getPagination } = require('../utils/helpers');

const adminLogin = async (req, res, next) => { try { success(res, await adminService.adminLogin(req.body)); } catch (e) { next(e); } };
const getDashboard = async (req, res, next) => { try { success(res, await adminService.getDashboardStats()); } catch (e) { next(e); } };

const getUsers = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { users, total } = await adminService.getUsers(pag, req.query);
        paginated(res, users, pag.page, pag.limit, total);
    } catch (e) { next(e); }
};
const getUser = async (req, res, next) => { try { success(res, await adminService.getUser(req.params.id)); } catch (e) { next(e); } };
const toggleUserActive = async (req, res, next) => { try { success(res, await adminService.toggleUserActive(req.params.id), 'User status updated'); } catch (e) { next(e); } };

// Suppliers
const getPendingSuppliers = async (req, res, next) => { try { success(res, await adminService.getPendingSuppliers()); } catch (e) { next(e); } };
const getAllSuppliers = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { suppliers, total } = await adminService.getAllSuppliers(pag, req.query);
        paginated(res, suppliers, pag.page, pag.limit, total);
    } catch (e) { next(e); }
};
const verifySupplier = async (req, res, next) => { try { success(res, await adminService.verifySupplier(req.params.id, req.body), 'Supplier updated'); } catch (e) { next(e); } };

// Dealers
const getPendingDealers = async (req, res, next) => { try { success(res, await adminService.getPendingDealers()); } catch (e) { next(e); } };
const getAllDealers = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { dealers, total } = await adminService.getAllDealers(pag, req.query);
        paginated(res, dealers, pag.page, pag.limit, total);
    } catch (e) { next(e); }
};
const verifyDealer = async (req, res, next) => { try { success(res, await adminService.verifyDealer(req.params.id, req.body), 'Dealer updated'); } catch (e) { next(e); } };

// Products
const getProducts = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { products, total } = await adminService.getProducts(pag, req.query);
        paginated(res, products, pag.page, pag.limit, total);
    } catch (e) { next(e); }
};
const approveProduct = async (req, res, next) => { try { success(res, await adminService.approveProduct(req.params.id), 'Product approved'); } catch (e) { next(e); } };
const rejectProduct = async (req, res, next) => { try { success(res, await adminService.rejectProduct(req.params.id), 'Product rejected'); } catch (e) { next(e); } };

const getAllOrders = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { orders, total } = await adminService.getAllOrders(pag, req.query);
        paginated(res, orders, pag.page, pag.limit, total);
    } catch (e) { next(e); }
};

const createScheme = async (req, res, next) => { try { created(res, await adminService.createScheme(req.body)); } catch (e) { next(e); } };
const updateScheme = async (req, res, next) => { try { success(res, await adminService.updateScheme(req.params.id, req.body)); } catch (e) { next(e); } };
const deleteScheme = async (req, res, next) => { try { success(res, await adminService.deleteScheme(req.params.id), 'Scheme deleted'); } catch (e) { next(e); } };
const broadcastNotification = async (req, res, next) => { try { success(res, await adminService.broadcastNotification(req.body), 'Notifications sent'); } catch (e) { next(e); } };

module.exports = {
    adminLogin, getDashboard, getUsers, getUser, toggleUserActive,
    getPendingSuppliers, getAllSuppliers, verifySupplier,
    getPendingDealers, getAllDealers, verifyDealer,
    getProducts, approveProduct, rejectProduct, getAllOrders,
    createScheme, updateScheme, deleteScheme, broadcastNotification
};
