const prisma = require('../config/database');

const getNotifications = async (userId, { page, limit, skip }) => {
    const [notifications, total, unread] = await Promise.all([
        prisma.notification.findMany({
            where: { userId }, skip, take: limit,
            orderBy: { createdAt: 'desc' },
        }),
        prisma.notification.count({ where: { userId } }),
        prisma.notification.count({ where: { userId, isRead: false } }),
    ]);
    return { notifications, total, unread };
};

const markRead = async (userId, notifId) => {
    return prisma.notification.updateMany({ where: { id: notifId, userId }, data: { isRead: true } });
};

const markAllRead = async (userId) => {
    return prisma.notification.updateMany({ where: { userId, isRead: false }, data: { isRead: true } });
};

const deleteNotification = async (userId, notifId) => {
    return prisma.notification.deleteMany({ where: { id: notifId, userId } });
};

const saveFCMToken = async (userId, { token, device }) => {
    return prisma.fCMToken.upsert({
        where: { userId_token: { userId, token } },
        create: { userId, token, device },
        update: { device },
    });
};

const createNotification = async (userId, { title, body, type, data }) => {
    return prisma.notification.create({ data: { userId, title, body, type, data } });
};

const broadcastNotification = async ({ targetType, district, title, body, type }) => {
    let where = {};
    if (targetType === 'farmers') where = { role: 'FARMER' };
    else if (targetType === 'suppliers') where = { role: 'SUPPLIER' };
    if (district) {
        const farmersInDistrict = await prisma.farmer.findMany({ where: { district: { contains: district, mode: 'insensitive' } }, select: { userId: true } });
        const userIds = farmersInDistrict.map(f => f.userId);
        where.id = { in: userIds };
    }

    const users = await prisma.user.findMany({ where, select: { id: true } });
    const notifications = await prisma.notification.createMany({
        data: users.map(u => ({ userId: u.id, title, body, type })),
    });
    return { sent: notifications.count };
};

module.exports = { getNotifications, markRead, markAllRead, deleteNotification, saveFCMToken, createNotification, broadcastNotification };
