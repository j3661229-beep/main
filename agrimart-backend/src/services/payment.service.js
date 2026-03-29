const prisma = require('../config/database');
const razorpay = require('../config/razorpay');
const { toPaise, generateOrderId, verifyRazorpaySignature, verifyWebhookSignature } = require('../utils/helpers');
const logger = require('../utils/logger');

let twilioClient;
if (process.env.TWILIO_ACCOUNT_SID) {
    twilioClient = require('twilio')(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
}

const createPaymentOrder = async (orderId) => {
    const order = await prisma.order.findUnique({ where: { id: orderId } });
    if (!order) throw Object.assign(new Error('Order not found'), { statusCode: 404 });

    const rzpOrder = await razorpay.orders.create({
        amount: toPaise(order.totalAmount),
        currency: 'INR',
        receipt: generateOrderId(),
        notes: { orderId },
    });

    await prisma.order.update({ where: { id: orderId }, data: { razorpayOrderId: rzpOrder.id } });
    await prisma.payment.upsert({
        where: { orderId },
        create: { orderId, razorpayOrderId: rzpOrder.id, amount: order.totalAmount, status: 'PENDING' },
        update: { razorpayOrderId: rzpOrder.id },
    });

    return { razorpayOrderId: rzpOrder.id, amount: order.totalAmount, currency: 'INR', keyId: process.env.RAZORPAY_KEY_ID };
};

const verifyPayment = async ({ razorpayOrderId, razorpayPaymentId, razorpaySignature }) => {
    const isValid = verifyRazorpaySignature(razorpayOrderId, razorpayPaymentId, razorpaySignature);
    if (!isValid) throw Object.assign(new Error('Payment verification failed — invalid signature'), { statusCode: 400 });

    const order = await prisma.order.findFirst({ where: { razorpayOrderId } });
    if (!order) throw Object.assign(new Error('Order not found for this payment'), { statusCode: 404 });

    await prisma.$transaction([
        prisma.order.update({ where: { id: order.id }, data: { status: 'PAYMENT_CONFIRMED', paymentId: razorpayPaymentId, paymentStatus: 'SUCCESS' } }),
        prisma.payment.update({ where: { orderId: order.id }, data: { status: 'SUCCESS', razorpayPaymentId, method: 'razorpay' } }),
    ]);

    // Deduct stock
    const items = await prisma.orderItem.findMany({ where: { orderId: order.id } });
    for (const item of items) {
        await prisma.product.update({ where: { id: item.productId }, data: { stockQuantity: { decrement: item.quantity } } });
    }

    // Notify farmer via WhatsApp
    if (twilioClient) {
        const farmer = await prisma.farmer.findUnique({ where: { id: order.farmerId }, include: { user: true } });
        try {
            await twilioClient.messages.create({
                from: process.env.TWILIO_WHATSAPP_FROM,
                to: `whatsapp:${farmer.user.phone}`,
                body: `✅ AgriMart: Payment of ₹${order.totalAmount} confirmed for order #${order.id.slice(-6)}. Your items will be dispatched shortly.`,
            });
        } catch (e) { logger.error('WhatsApp notify error:', e.message); }
    }

    return { orderId: order.id, status: 'PAYMENT_CONFIRMED' };
};

const getPayment = async (orderId) => {
    const payment = await prisma.payment.findUnique({ where: { orderId }, include: { order: true } });
    if (!payment) throw Object.assign(new Error('Payment not found'), { statusCode: 404 });
    return payment;
};

const handleWebhook = async (rawBody, signature) => {
    if (!verifyWebhookSignature(rawBody, signature)) {
        throw Object.assign(new Error('Invalid webhook signature'), { statusCode: 400 });
    }
    const event = JSON.parse(rawBody);
    logger.info('Razorpay webhook:', event.event);

    if (event.event === 'payment.failed') {
        const payment = event.payload.payment.entity;
        const order = await prisma.order.findFirst({ where: { razorpayOrderId: payment.order_id } });
        if (order) {
            await prisma.order.update({ where: { id: order.id }, data: { paymentStatus: 'FAILED' } });
            await prisma.payment.update({ where: { orderId: order.id }, data: { status: 'FAILED', failureReason: payment.error_description } });
        }
    }
    return { received: true };
};

const requestRefund = async ({ orderId, amount, reason }) => {
    const payment = await prisma.payment.findUnique({ where: { orderId } });
    if (!payment || payment.status !== 'SUCCESS') throw Object.assign(new Error('No valid payment to refund'), { statusCode: 400 });

    const refund = await razorpay.payments.refund(payment.razorpayPaymentId, { amount: toPaise(amount || payment.amount), notes: { reason } });
    await prisma.payment.update({ where: { orderId }, data: { status: 'REFUNDED', refundId: refund.id, refundAmount: amount || payment.amount, refundReason: reason } });
    await prisma.order.update({ where: { id: orderId }, data: { status: 'REFUNDED', paymentStatus: 'REFUNDED' } });
    return refund;
};

const confirmCashOnDelivery = async (orderId, farmerId) => {
    const order = await prisma.order.findFirst({ where: { id: orderId, farmerId } });
    if (!order) throw Object.assign(new Error('Order not found'), { statusCode: 404 });
    if (order.paymentStatus !== 'PENDING') {
        throw Object.assign(new Error('Payment already processed for this order'), { statusCode: 400 });
    }

    await prisma.payment.upsert({
        where: { orderId },
        create: { orderId, amount: order.totalAmount, status: 'PENDING', method: 'cod' },
        update: { method: 'cod', status: 'PENDING' },
    });

    await prisma.order.update({
        where: { id: orderId },
        data: { status: 'PROCESSING', paymentStatus: 'PENDING' },
    });

    return { orderId, status: 'PROCESSING', paymentMethod: 'cod' };
};

module.exports = { createPaymentOrder, verifyPayment, getPayment, handleWebhook, requestRefund, confirmCashOnDelivery };
