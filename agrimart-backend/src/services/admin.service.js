const prisma = require('../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Admin login with password
const adminLogin = async ({ phone, password }) => {
    const user = await prisma.user.findUnique({ where: { phone } });
    if (!user || user.role !== 'ADMIN') throw Object.assign(new Error('Invalid admin credentials'), { statusCode: 401 });
    // In production, store hashed password; for now use env check
    if (password !== process.env.ADMIN_PASSWORD) throw Object.assign(new Error('Invalid password'), { statusCode: 401 });
    const token = jwt.sign({ userId: user.id, role: 'ADMIN' }, process.env.JWT_SECRET || 'dev_secret', { expiresIn: '12h' });
    return { user, token };
};

// Dashboard stats
const getDashboardStats = async () => {
    const [
        totalUsers, totalFarmers, totalSuppliers, totalDealers,
        totalOrders, totalRevenue, pendingOrders,
        pendingSuppliers, totalProducts, newUsersThisMonth,
    ] = await Promise.all([
        prisma.user.count({ where: { isActive: true } }),
        prisma.user.count({ where: { role: 'FARMER', isActive: true } }),
        prisma.user.count({ where: { role: 'SUPPLIER', isActive: true } }),
        prisma.user.count({ where: { role: 'DEALER', isActive: true } }),
        prisma.order.count(),
        prisma.payment.aggregate({ where: { status: 'SUCCESS' }, _sum: { amount: true } }),
        prisma.order.count({ where: { status: { in: ['PENDING', 'PAYMENT_CONFIRMED'] } } }),
        prisma.supplier.count({ where: { isVerified: false } }),
        prisma.product.count({ where: { isActive: true } }),
        prisma.user.count({ where: { createdAt: { gte: new Date(new Date().setDate(1)) } } }),
    ]);

    // Recent orders
    const recentOrders = await prisma.order.findMany({
        take: 10, orderBy: { createdAt: 'desc' },
        include: { farmer: { include: { user: true } }, items: { include: { product: true } }, payment: true },
    });

    // Revenue trend last 7 days
    const trend = await Promise.all(
        Array.from({ length: 7 }, (_, i) => {
            const start = new Date(); start.setDate(start.getDate() - i); start.setHours(0, 0, 0, 0);
            const end = new Date(start); end.setHours(23, 59, 59, 999);
            return prisma.payment.aggregate({ where: { status: 'SUCCESS', createdAt: { gte: start, lte: end } }, _sum: { amount: true } })
                .then(r => ({ date: start.toISOString().split('T')[0], revenue: r._sum.amount || 0 }));
        })
    );

    return {
        stats: { totalUsers, totalFarmers, totalSuppliers, totalDealers, totalOrders, totalRevenue: totalRevenue._sum.amount || 0, pendingOrders, pendingSuppliers, totalProducts, newUsersThisMonth },
        recentOrders,
        revenueTrend: trend.reverse(),
    };
};

// Users
const getUsers = async ({ page, limit, skip }, { role, search, isActive }) => {
    const where = {};
    if (role) where.role = role;
    if (isActive !== undefined) where.isActive = isActive === 'true';
    if (search) where.OR = [{ name: { contains: search, mode: 'insensitive' } }, { phone: { contains: search } }];
    const [users, total] = await Promise.all([
        prisma.user.findMany({ where, skip, take: limit, orderBy: { createdAt: 'desc' }, include: { farmer: true, supplier: true } }),
        prisma.user.count({ where }),
    ]);
    return { users, total };
};

const getUser = async (id) => {
    const user = await prisma.user.findUnique({ where: { id }, include: { farmer: { include: { orders: { take: 5 } } }, supplier: { include: { products: { take: 5 } } } } });
    if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });
    return user;
};

const toggleUserActive = async (id) => {
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user) throw Object.assign(new Error('User not found'), { statusCode: 404 });
    return prisma.user.update({ where: { id }, data: { isActive: !user.isActive } });
};

// Supplier verification
const getPendingSuppliers = async () => {
    return prisma.supplier.findMany({
        where: { isVerified: false, rejectedAt: null },
        include: { user: true },
        orderBy: { createdAt: 'desc' },
    });
};

const getAllSuppliers = async ({ page, limit, skip }, { search, isVerified }) => {
    const where = {};
    if (isVerified !== undefined) where.isVerified = isVerified === 'true';
    if (search) {
        where.OR = [
            { businessName: { contains: search, mode: 'insensitive' } },
            { address: { contains: search, mode: 'insensitive' } },
            { user: { name: { contains: search, mode: 'insensitive' } } },
            { user: { phone: { contains: search } } }
        ];
    }
    const [suppliers, total] = await Promise.all([
        prisma.supplier.findMany({
            where, skip, take: limit,
            orderBy: { createdAt: 'desc' },
            include: { user: true, products: { take: 5 } }
        }),
        prisma.supplier.count({ where })
    ]);
    return { suppliers, total };
};

const verifySupplier = async (supplierId, { action, reason }) => {
    if (action === 'approve') {
        return prisma.supplier.update({ where: { id: supplierId }, data: { isVerified: true, verifiedAt: new Date() } });
    } else if (action === 'reject') {
        return prisma.supplier.update({ where: { id: supplierId }, data: { rejectedAt: new Date(), rejectedReason: reason } });
    }
    throw Object.assign(new Error('Action must be approve or reject'), { statusCode: 400 });
};

// Products
const getProducts = async ({ page, limit, skip }, { isApproved, category, search }) => {
    const where = {};
    if (isApproved !== undefined) where.isApproved = isApproved === 'true';
    if (category) where.category = category;
    if (search) where.name = { contains: search, mode: 'insensitive' };
    const [products, total] = await Promise.all([
        prisma.product.findMany({ where, skip, take: limit, orderBy: { createdAt: 'desc' }, include: { supplier: { include: { user: true } } } }),
        prisma.product.count({ where }),
    ]);
    return { products, total };
};

const approveProduct = async (productId) => {
    return prisma.product.update({ where: { id: productId }, data: { isApproved: true } });
};

const rejectProduct = async (productId) => {
    return prisma.product.update({ where: { id: productId }, data: { isApproved: false, isActive: false } });
};

// Orders
const getAllOrders = async ({ page, limit, skip }, { status, search }) => {
    const where = {};
    if (status) where.status = status;
    if (search) where.id = { contains: search };
    const [orders, total] = await Promise.all([
        prisma.order.findMany({
            where, skip, take: limit,
            orderBy: { createdAt: 'desc' },
            include: { farmer: { include: { user: true } }, items: { include: { product: true } }, payment: true },
        }),
        prisma.order.count({ where }),
    ]);
    return { orders, total };
};

// Schemes admin
const schemeService = require('./scheme.service');
const { createScheme, updateScheme, deleteScheme } = schemeService;

// Broadcast notification
const notifService = require('./notification.service');
const { broadcastNotification } = notifService;

module.exports = { adminLogin, getDashboardStats, getUsers, getUser, toggleUserActive, getPendingSuppliers, getAllSuppliers, verifySupplier, getProducts, approveProduct, rejectProduct, getAllOrders, createScheme, updateScheme, deleteScheme, broadcastNotification };
