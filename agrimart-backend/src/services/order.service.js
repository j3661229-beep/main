const prisma = require('../config/database');
const { sendNotification } = require('./onesignal.service');

const createOrder = async (farmerId, { deliveryAddress, deliveryLat, deliveryLng, notes, paymentMethod }) => {
    // Get cart
    const cart = await prisma.cart.findUnique({
        where: { farmerId },
        include: { items: { include: { product: { include: { supplier: true } } } } },
    });
    if (!cart || cart.items.length === 0) throw Object.assign(new Error('Cart is empty'), { statusCode: 400 });

    // Validate stock
    for (const item of cart.items) {
        if (item.product.stockQuantity < item.quantity) {
            throw Object.assign(new Error(`Insufficient stock for ${item.product.name}`), { statusCode: 400 });
        }
    }

    const totalAmount = cart.items.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
    const method = paymentMethod || 'cod';
    const isCod = method === 'cod';

    const order = await prisma.$transaction(async (tx) => {
        const newOrder = await tx.order.create({
            data: {
                farmerId,
                totalAmount,
                deliveryAddress,
                deliveryLat: deliveryLat ? parseFloat(deliveryLat) : null,
                deliveryLng: deliveryLng ? parseFloat(deliveryLng) : null,
                notes,
                paymentMethod: method,
                status: isCod ? 'PROCESSING' : 'PENDING',
                paymentStatus: 'PENDING',
                items: {
                    create: cart.items.map(item => ({
                        productId: item.productId,
                        supplierId: item.product.supplierId,
                        quantity: item.quantity,
                        price: item.product.price * item.quantity,
                    })),
                },
            },
            include: { items: { include: { product: true, supplier: { include: { user: true } } } } },
        });

        if (isCod) {
            // Deduct stock immediately
            for (const item of cart.items) {
                await tx.product.update({
                    where: { id: item.productId },
                    data: { stockQuantity: { decrement: item.quantity } }
                });
            }
            // Create payment record
            await tx.payment.create({
                data: { orderId: newOrder.id, amount: totalAmount, status: 'PENDING', method: 'cod' }
            });
        }

        // Clear cart
        await tx.cartItem.deleteMany({ where: { cartId: cart.id } });
        return newOrder;
    });

    // Notify Suppliers (Don't await)
    order.items.forEach(item => {
        sendNotification({
            users: [item.supplier.user.id],
            title: 'New Order Received! 📦',
            message: `You have a new order for ${item.product.name} from a farmer.`,
            data: { orderId: order.id, type: 'ORDER' }
        });
    });

    return order;
};

const getOrders = async (farmerId, { page, limit, skip }) => {
    const [orders, total] = await Promise.all([
        prisma.order.findMany({
            where: { farmerId }, skip, take: limit,
            orderBy: { createdAt: 'desc' },
            include: { items: { include: { product: true } }, payment: true },
        }),
        prisma.order.count({ where: { farmerId } }),
    ]);
    return { orders, total };
};

const getOrder = async (farmerId, orderId) => {
    const order = await prisma.order.findFirst({
        where: { id: orderId, farmerId },
        include: { items: { include: { product: true, supplier: { include: { user: true } }, review: true } }, payment: true },
    });
    if (!order) throw Object.assign(new Error('Order not found'), { statusCode: 404 });
    return order;
};

const cancelOrder = async (farmerId, orderId) => {
    const order = await prisma.order.findFirst({ where: { id: orderId, farmerId } });
    if (!order) throw Object.assign(new Error('Order not found'), { statusCode: 404 });
    if (!['PENDING', 'PAYMENT_CONFIRMED'].includes(order.status)) {
        throw Object.assign(new Error('Cannot cancel order at this stage'), { statusCode: 400 });
    }
    return prisma.order.update({ where: { id: orderId }, data: { status: 'CANCELLED' } });
};

const getTracking = async (farmerId, orderId) => {
    const order = await getOrder(farmerId, orderId);

    // Standard Delivery Tracking Map
    const trackingMap = [
        { status: 'PENDING', label: 'Order Placed' },
        { status: 'PROCESSING', label: 'Preparing Order' },
        { status: 'DISPATCHED', label: 'Dispatched' },
        { status: 'OUT_FOR_DELIVERY', label: 'Out for Delivery' },
        { status: 'DELIVERED', label: 'Delivered' }
    ];

    // Normalize DB status to one of these if needed
    let currentStatus = order.status;
    if (currentStatus === 'PAYMENT_CONFIRMED') currentStatus = 'PENDING';

    let currentIndex = trackingMap.findIndex(s => s.status === currentStatus);
    if (currentIndex === -1) currentIndex = 0; // fallback if cancelled or weird

    return {
        order,
        tracking: trackingMap.map((step, i) => ({
            status: step.status,
            label: step.label,
            completed: i <= currentIndex,
            current: i === currentIndex,
        })),
        progressPercent: Math.round((currentIndex / (trackingMap.length - 1)) * 100),
    };
};

module.exports = { createOrder, getOrders, getOrder, cancelOrder, getTracking };
