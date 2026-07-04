const paymentService = require('../services/payment.service');
const { success, error } = require('../utils/apiResponse');

const verifyUpi = async (req, res, next) => {
    try {
        const { orderId, utrNumber } = req.body;
        if (!orderId || !utrNumber) return error(res, 'orderId and utrNumber are required');
        const farmerId = req.user?.farmer?.id;
        if (!farmerId) return error(res, 'Farmer profile required', 403);
        success(res, await paymentService.verifyUpiPayment(orderId, farmerId, utrNumber), 'UPI payment verified');
    } catch (e) { next(e); }
};

const getUpiDetails = async (req, res, next) => {
    try {
        const farmerId = req.user?.farmer?.id;
        if (!farmerId) return error(res, 'Farmer profile required', 403);
        success(res, await paymentService.getOrderSupplierUpiDetails(req.params.orderId, farmerId));
    } catch (e) { next(e); }
};

const getPayment = async (req, res, next) => {
    try { success(res, await paymentService.getPayment(req.params.orderId)); } catch (e) { next(e); }
};

const confirmCashOnDelivery = async (req, res, next) => {
    try {
        success(
            res,
            await paymentService.confirmCashOnDelivery(req.body.orderId, req.user.farmer.id),
            'Cash on delivery selected'
        );
    } catch (e) { next(e); }
};

module.exports = { verifyUpi, getUpiDetails, getPayment, confirmCashOnDelivery };
