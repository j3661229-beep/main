const farmerService = require('../services/farmer.service');
const { success, error, paginated } = require('../utils/apiResponse');
const { getPagination } = require('../utils/helpers');

const getFarmerId = (req) => req.user?.farmer?.id;

const getProfile = async (req, res, next) => {
    try {
        const data = await farmerService.getProfile(getFarmerId(req));
        success(res, data);
    } catch (err) { next(err); }
};

const updateProfile = async (req, res, next) => {
    try {
        const data = await farmerService.updateProfile(getFarmerId(req), req.body);
        success(res, data, 'Profile updated');
    } catch (err) { next(err); }
};

const updateFarmDetails = async (req, res, next) => {
    try {
        const data = await farmerService.updateFarmDetails(getFarmerId(req), req.body);
        success(res, data, 'Farm details updated');
    } catch (err) { next(err); }
};

const getDashboard = async (req, res, next) => {
    try {
        const data = await farmerService.getDashboard(getFarmerId(req));
        success(res, data);
    } catch (err) { next(err); }
};

const getOrders = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { orders, total } = await farmerService.getOrders(getFarmerId(req), pag);
        paginated(res, orders, pag.page, pag.limit, total);
    } catch (err) { next(err); }
};

const getOrder = async (req, res, next) => {
    try {
        const data = await farmerService.getOrder(getFarmerId(req), req.params.id);
        success(res, data);
    } catch (err) { next(err); }
};

const createPriceAlert = async (req, res, next) => {
    try {
        const data = await farmerService.createPriceAlert(getFarmerId(req), req.body);
        success(res, data, 'Price alert created', 201);
    } catch (err) { next(err); }
};

const getPriceAlerts = async (req, res, next) => {
    try {
        const data = await farmerService.getPriceAlerts(getFarmerId(req));
        success(res, data);
    } catch (err) { next(err); }
};

const deletePriceAlert = async (req, res, next) => {
    try {
        await farmerService.deletePriceAlert(getFarmerId(req), req.params.id);
        success(res, {}, 'Alert deleted');
    } catch (err) { next(err); }
};

const getSoilReports = async (req, res, next) => {
    try {
        const data = await farmerService.getSoilReports(getFarmerId(req));
        success(res, data);
    } catch (err) { next(err); }
};

const getSoilReport = async (req, res, next) => {
    try {
        const data = await farmerService.getSoilReport(getFarmerId(req), req.params.id);
        success(res, data);
    } catch (err) { next(err); }
};

module.exports = { getProfile, updateProfile, updateFarmDetails, getDashboard, getOrders, getOrder, createPriceAlert, getPriceAlerts, deletePriceAlert, getSoilReports, getSoilReport };
