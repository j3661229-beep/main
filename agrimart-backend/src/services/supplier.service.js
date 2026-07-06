const prisma = require('../config/database');
const { sendNotification } = require('./onesignal.service');

const formatOrderItem = (item) => ({
    ...item,
    farmerName: item.order?.farmer?.user?.name ?? 'Farmer',
    productName: item.product?.name ?? 'Product',
    amount: (item.price || 0) * (item.quantity || 1),
    totalAmount: (item.price || 0) * (item.quantity || 1),
});

const getProfile = async (supplierId) => {
    return prisma.supplier.findUnique({ where: { id: supplierId }, include: { user: true } });
};

const updateProfile = async (supplierId, data) => {
    const supplier = await prisma.supplier.findUnique({ where: { id: supplierId } });
    if (data.name || data.language) {
        await prisma.user.update({ where: { id: supplier.userId }, data: { name: data.name, language: data.language } });
    }
    return prisma.supplier.update({
        where: { id: supplierId },
        data: {
            businessName: data.businessName,
            gstNumber: data.gstNumber,
            address: data.address,
            district: data.district,
            pincode: data.pincode,
            latitude: data.latitude ? parseFloat(data.latitude) : undefined,
            longitude: data.longitude ? parseFloat(data.longitude) : undefined,
            bankAccountNo: data.bankAccountNo,
            ifscCode: data.ifscCode,
            upiId: data.upiId,
            state: data.state,
        },
        include: { user: true },
    });
};

const getDashboard = async (supplierId) => {
    const supplier = await prisma.supplier.findUnique({ where: { id: supplierId }, include: { user: true } });
    const now = new Date();
    const weekAgo = new Date(now);
    weekAgo.setDate(weekAgo.getDate() - 7);
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const sixMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 5, 1);

    const [
        totalRevenueAgg,
        totalOrders,
        pendingOrders,
        totalProducts,
        activeListings,
        ordersThisWeek,
        revenueThisMonthAgg,
        recentRaw,
        monthlyItems,
    ] = await Promise.all([
        prisma.orderItem.aggregate({
            where: { supplierId, status: 'DELIVERED' },
            _sum: { price: true },
        }),
        prisma.orderItem.count({ where: { supplierId } }),
        prisma.orderItem.count({ where: { supplierId, status: 'PENDING' } }),
        prisma.product.count({ where: { supplierId, isActive: true } }),
        prisma.product.count({ where: { supplierId, isActive: true, isApproved: true } }),
        prisma.orderItem.count({ where: { supplierId, createdAt: { gte: weekAgo } } }),
        prisma.orderItem.aggregate({
            where: { supplierId, status: 'DELIVERED', createdAt: { gte: monthStart } },
            _sum: { price: true },
        }),
        prisma.orderItem.findMany({
            where: { supplierId },
            take: 10,
            orderBy: { createdAt: 'desc' },
            include: { product: true, order: { include: { farmer: { include: { user: true } } } } },
        }),
        prisma.orderItem.findMany({
            where: { supplierId, status: 'DELIVERED', createdAt: { gte: sixMonthsAgo } },
            select: { price: true, quantity: true, createdAt: true },
        }),
    ]);

    const recentOrders = recentRaw.map(formatOrderItem);
    const totalRevenue = totalRevenueAgg._sum.price || 0;
    const revenueThisMonth = revenueThisMonthAgg._sum.price || 0;

    const monthlyMap = {};
    for (const item of monthlyItems) {
        const key = `${item.createdAt.getFullYear()}-${String(item.createdAt.getMonth() + 1).padStart(2, '0')}`;
        monthlyMap[key] = (monthlyMap[key] || 0) + (item.price * (item.quantity || 1));
    }
    const monthlyRevenue = Object.entries(monthlyMap)
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([month, revenue]) => ({ month, revenue }));

    return {
        supplier,
        totalRevenue,
        totalOrders,
        pendingOrders,
        totalProducts,
        ordersThisWeek,
        revenueThisMonth,
        activeListings,
        recentOrders,
        monthlyRevenue,
    };
};

const getOrders = async (supplierId, { page, limit, skip }, filters) => {
    const where = { supplierId };
    if (filters.status) where.status = filters.status;
    const [orders, total] = await Promise.all([
        prisma.orderItem.findMany({
            where, skip, take: limit,
            orderBy: { createdAt: 'desc' },
            include: { product: true, order: { include: { farmer: { include: { user: true } } } } },
        }),
        prisma.orderItem.count({ where }),
    ]);
    return { orders: orders.map(formatOrderItem), total };
};

const getOrder = async (supplierId, itemId) => {
    const item = await prisma.orderItem.findFirst({
        where: { id: itemId, supplierId },
        include: { product: true, order: { include: { farmer: { include: { user: true } }, items: { include: { product: true } } } }, review: true },
    });
    if (!item) throw Object.assign(new Error('Order item not found'), { statusCode: 404 });
    return item;
};

const updateOrderStatus = async (supplierId, itemId, status) => {
    const normalized = status === 'CONFIRMED' ? 'PROCESSING' : status;
    const validTransitions = {
        PENDING: ['PROCESSING', 'CANCELLED'],
        PAYMENT_CONFIRMED: ['PROCESSING'],
        PROCESSING: ['DISPATCHED', 'OUT_FOR_DELIVERY'],
        DISPATCHED: ['OUT_FOR_DELIVERY', 'DELIVERED'],
        OUT_FOR_DELIVERY: ['DELIVERED'],
    };
    const item = await prisma.orderItem.findFirst({ where: { id: itemId, supplierId } });
    if (!item) throw Object.assign(new Error('Order not found'), { statusCode: 404 });
    if (!validTransitions[item.status]?.includes(normalized)) {
        throw Object.assign(new Error(`Cannot transition from ${item.status} to ${normalized}`), { statusCode: 400 });
    }
    const updatedItem = await prisma.orderItem.update({ where: { id: itemId }, data: { status: normalized }, include: { order: { include: { farmer: true } }, product: true } });

    // Notify farmer (Don't await)
    const statusLabels = {
        PROCESSING: 'is being prepared',
        DISPATCHED: 'is ready for pickup! 🏁',
        OUT_FOR_DELIVERY: 'is out for delivery',
        DELIVERED: 'has been picked up'
    };
    if (statusLabels[normalized]) {
        const title = `Order Update: ${updatedItem.product.name}`;
        const message = `Your item ${statusLabels[normalized]}. Visit the shop soon!`;
        
        sendNotification({
            users: [updatedItem.order.farmer.userId],
            title,
            message,
            data: { orderId: updatedItem.orderId, type: 'ORDER' }
        });

        // Save to DB so it shows up in in-app notifications screen
        const notifService = require('./notification.service');
        await notifService.createNotification(updatedItem.order.farmer.userId, { 
            title, 
            body: message, 
            type: 'ORDER', 
            data: { orderId: updatedItem.orderId } 
        });
    }

    return formatOrderItem(updatedItem);
};

const getProducts = async (supplierId, { page, limit, skip }) => {
    const [products, total] = await Promise.all([
        prisma.product.findMany({ where: { supplierId }, skip, take: limit, orderBy: { createdAt: 'desc' } }),
        prisma.product.count({ where: { supplierId } }),
    ]);
    return { products, total };
};

const getAnalytics = async (supplierId) => {
    const topProducts = await prisma.orderItem.groupBy({
        by: ['productId'],
        where: { supplierId },
        _sum: { price: true },
        _count: { productId: true },
        orderBy: { _sum: { price: 'desc' } },
        take: 10,
    });
    return { topProducts };
};

module.exports = { getProfile, updateProfile, getDashboard, getOrders, getOrder, updateOrderStatus, getProducts, getAnalytics };
