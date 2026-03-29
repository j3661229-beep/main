const orderService = require('../services/order.service');
const { success, created, paginated } = require('../utils/apiResponse');
const { getPagination } = require('../utils/helpers');

const createOrder = async (req, res, next) => {
    try { created(res, await orderService.createOrder(req.user.farmer.id, req.body)); } catch (e) { next(e); }
};
const getOrders = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { orders, total } = await orderService.getOrders(req.user.farmer.id, pag);
        paginated(res, orders, pag.page, pag.limit, total);
    } catch (e) { next(e); }
};
const getOrder = async (req, res, next) => { try { success(res, await orderService.getOrder(req.user.farmer.id, req.params.id)); } catch (e) { next(e); } };
const cancelOrder = async (req, res, next) => { try { success(res, await orderService.cancelOrder(req.user.farmer.id, req.params.id), 'Order cancelled'); } catch (e) { next(e); } };
const getTracking = async (req, res, next) => { try { success(res, await orderService.getTracking(req.user.farmer.id, req.params.id)); } catch (e) { next(e); } };

module.exports = { createOrder, getOrders, getOrder, cancelOrder, getTracking };
