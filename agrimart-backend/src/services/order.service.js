const prisma = require('../config/database');

const createOrder = async (farmerId, { deliveryAddress, deliveryLat, deliveryLng, notes }) => {
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

    const order = await prisma.$transaction(async (tx) => {
        const newOrder = await tx.order.create({
            data: {
                farmerId,
                totalAmount,
                deliveryAddress,
                deliveryLat: deliveryLat ? parseFloat(deliveryLat) : null,
                deliveryLng: deliveryLng ? parseFloat(deliveryLng) : null,
                notes,
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
        // Clear cart
        await tx.cartItem.deleteMany({ where: { cartId: cart.id } });
        return newOrder;
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

    // We map existing enums to the BOPIS model
    const trackingMap = [
        { status: 'PENDING', label: 'Order Placed' },
        { status: 'PROCESSING', label: 'Preparing Order' },
        { status: 'DISPATCHED', label: 'Ready for Pickup' },
        { status: 'DELIVERED', label: 'Picked Up' }
    ];

    // Normalize DB status to one of these 4 if needed (e.g. PAYMENT_CONFIRMED -> PENDING step basically)
    let currentStatus = order.status;
    if (currentStatus === 'PAYMENT_CONFIRMED') currentStatus = 'PENDING';
    if (currentStatus === 'OUT_FOR_DELIVERY') currentStatus = 'DELIVERED';

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
