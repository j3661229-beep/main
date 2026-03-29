const prisma = require('../config/database');

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
        },
        include: { user: true },
    });
};

const getDashboard = async (supplierId) => {
    const supplier = await prisma.supplier.findUnique({ where: { id: supplierId }, include: { user: true } });

    const [totalRevenue, totalOrders, pendingOrders, totalProducts] = await Promise.all([
        prisma.orderItem.aggregate({ where: { supplierId, status: 'DELIVERED' }, _sum: { price: true } }),
        prisma.orderItem.count({ where: { supplierId } }),
        prisma.orderItem.count({ where: { supplierId, status: 'PENDING' } }),
        prisma.product.count({ where: { supplierId, isActive: true } }),
    ]);

    const recentOrders = await prisma.orderItem.findMany({
        where: { supplierId },
        take: 10,
        orderBy: { createdAt: 'desc' },
        include: { product: true, order: { include: { farmer: { include: { user: true } } } } },
    });

    // Monthly revenue (last 6 months)
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    const monthlyRevenue = await prisma.orderItem.groupBy({
        by: ['createdAt'],
        where: { supplierId, status: 'DELIVERED', createdAt: { gte: sixMonthsAgo } },
        _sum: { price: true },
    });

    return { supplier, totalRevenue: totalRevenue._sum.price || 0, totalOrders, pendingOrders, totalProducts, recentOrders, monthlyRevenue };
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
    return { orders, total };
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
    const validTransitions = {
        PENDING: ['PROCESSING', 'CANCELLED'],
        PAYMENT_CONFIRMED: ['PROCESSING'],
        PROCESSING: ['DISPATCHED'],
        DISPATCHED: ['OUT_FOR_DELIVERY'],
        OUT_FOR_DELIVERY: ['DELIVERED'],
    };
    const item = await prisma.orderItem.findFirst({ where: { id: itemId, supplierId } });
    if (!item) throw Object.assign(new Error('Order not found'), { statusCode: 404 });
    if (!validTransitions[item.status]?.includes(status)) {
        throw Object.assign(new Error(`Cannot transition from ${item.status} to ${status}`), { statusCode: 400 });
    }
    return prisma.orderItem.update({ where: { id: itemId }, data: { status } });
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
