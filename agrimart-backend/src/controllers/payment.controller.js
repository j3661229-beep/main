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
    try {
        const payment = await paymentService.getPayment(req.params.orderId);
        // Ensure the authenticated user owns this order (farmer, supplier, or admin)
        const userId = req.user.id;
        const role = req.user.role;
        if (role !== 'ADMIN') {
            const order = payment.order;
            const isOwner =
                (role === 'FARMER' && order?.farmerId === req.user?.farmer?.id) ||
                (role === 'SUPPLIER' && order?.items?.some?.((i) => i.supplierId === req.user?.supplier?.id));
            if (!isOwner) return error(res, 'Access denied', 403);
        }
        success(res, payment);
    } catch (e) { next(e); }
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
