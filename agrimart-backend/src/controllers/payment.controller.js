const paymentService = require('../services/payment.service');
const { success } = require('../utils/apiResponse');

const createOrder = async (req, res, next) => {
    try { success(res, await paymentService.createPaymentOrder(req.body.orderId)); } catch (e) { next(e); }
};
const verifyPayment = async (req, res, next) => {
    try { success(res, await paymentService.verifyPayment(req.body), 'Payment verified successfully'); } catch (e) { next(e); }
};
const getPayment = async (req, res, next) => {
    try { success(res, await paymentService.getPayment(req.params.orderId)); } catch (e) { next(e); }
};
const handleWebhook = async (req, res, next) => {
    try {
        const sig = req.headers['x-razorpay-signature'];
        const result = await paymentService.handleWebhook(req.body.toString(), sig);
        res.json(result);
    } catch (e) { next(e); }
};
const requestRefund = async (req, res, next) => {
    try { success(res, await paymentService.requestRefund(req.body), 'Refund initiated'); } catch (e) { next(e); }
};

module.exports = { createOrder, verifyPayment, getPayment, handleWebhook, requestRefund };
