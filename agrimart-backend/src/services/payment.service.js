const prisma = require('../config/database');
const { sendNotification } = require('./onesignal.service');
const logger = require('../utils/logger');

// ── UPI Payment Verification ────────────────────────────────────────────────
/**
 * Farmer submits UTR after paying via UPI to the supplier directly.
 * Order is marked PAYMENT_CONFIRMED. Supplier verifies from their side.
 */
const verifyUpiPayment = async (orderId, farmerId, utrNumber) => {
    if (!utrNumber || utrNumber.trim().length < 6) {
        throw Object.assign(new Error('Invalid UTR number. Please enter the 12-22 digit reference from your UPI app.'), { statusCode: 400 });
    }

    const order = await prisma.order.findFirst({
        where: { id: orderId, farmerId },
        include: { items: { include: { supplier: { include: { user: true } } } } }
    });
    if (!order) throw Object.assign(new Error('Order not found'), { statusCode: 404 });
    if (order.paymentStatus !== 'PENDING') {
        throw Object.assign(new Error('Payment already processed for this order'), { statusCode: 400 });
    }

    // Save UTR and mark payment confirmed
    await prisma.$transaction([
        prisma.order.update({
            where: { id: orderId },
            data: {
                utrNumber: utrNumber.trim(),
                paymentMethod: 'upi',
                status: 'PAYMENT_CONFIRMED',
                paymentStatus: 'SUCCESS',
            }
        }),
        prisma.payment.upsert({
            where: { orderId },
            create: { orderId, amount: order.totalAmount, status: 'SUCCESS', method: 'upi' },
            update: { status: 'SUCCESS', method: 'upi' },
        }),
    ]);

    // Deduct stock
    for (const item of order.items) {
        await prisma.product.update({
            where: { id: item.productId },
            data: { stockQuantity: { decrement: item.quantity } }
        });
    }

    // Notify each supplier to verify UTR in their panel
    const supplierIds = [...new Set(order.items.map(i => i.supplier.userId))];
    if (supplierIds.length > 0) {
        sendNotification({
            users: supplierIds,
            title: '💰 New UPI Payment Received',
            message: `Order #${orderId.slice(-6).toUpperCase()} — UTR: ${utrNumber.trim()}. Please verify in your panel.`,
            data: { orderId, type: 'PAYMENT' }
        });
    }

    return { orderId, status: 'PAYMENT_CONFIRMED', utrNumber: utrNumber.trim() };
};

// ── Get Supplier UPI Details for Order ─────────────────────────────────────
/**
 * Returns UPI IDs of all suppliers in the cart grouped by supplier,
 * so the checkout screen can show them to the farmer.
 */
const getOrderSupplierUpiDetails = async (orderId, farmerId) => {
    const order = await prisma.order.findFirst({
        where: { id: orderId, farmerId },
        include: {
            items: {
                include: {
                    supplier: { select: { id: true, businessName: true, upiId: true, district: true } },
                    product: { select: { name: true, price: true } }
                }
            }
        }
    });
    if (!order) throw Object.assign(new Error('Order not found'), { statusCode: 404 });

    // Group by supplier
    const supplierMap = {};
    for (const item of order.items) {
        const sid = item.supplier.id;
        if (!supplierMap[sid]) {
            supplierMap[sid] = {
                supplierId: sid,
                businessName: item.supplier.businessName,
                upiId: item.supplier.upiId || null,
                district: item.supplier.district,
                items: [],
                subtotal: 0,
            };
        }
        supplierMap[sid].items.push({ name: item.product.name, qty: item.quantity, price: item.price });
        supplierMap[sid].subtotal += item.price;
    }

    return {
        orderId,
        totalAmount: order.totalAmount,
        suppliers: Object.values(supplierMap),
    };
};

// ── COD ─────────────────────────────────────────────────────────────────────
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
        data: { status: 'PROCESSING', paymentStatus: 'PENDING', paymentMethod: 'cod' },
    });

    return { orderId, status: 'PROCESSING', paymentMethod: 'cod' };
};

// ── Get Payment ──────────────────────────────────────────────────────────────
const getPayment = async (orderId) => {
    const payment = await prisma.payment.findUnique({ where: { orderId }, include: { order: true } });
    if (!payment) throw Object.assign(new Error('Payment not found'), { statusCode: 404 });
    return payment;
};

module.exports = { verifyUpiPayment, getOrderSupplierUpiDetails, confirmCashOnDelivery, getPayment };
