const prisma = require('../config/database');
const { sendNotification } = require('./onesignal.service');

const getSchemes = async ({ isActive }) => {
    return prisma.governmentScheme.findMany({
        where: { isActive: isActive !== 'false' },
        orderBy: { createdAt: 'desc' },
    });
};

const getScheme = async (id) => {
    const scheme = await prisma.governmentScheme.findUnique({ where: { id } });
    if (!scheme) throw Object.assign(new Error('Scheme not found'), { statusCode: 404 });
    return scheme;
};

const getEligible = async (farmerId) => {
    const farmer = await prisma.farmer.findUnique({ where: { id: farmerId } });
    // All active schemes — in real app, filter by farmer profile
    return prisma.governmentScheme.findMany({ where: { isActive: true }, take: 10 });
};

const createScheme = async (data) => {
    const scheme = await prisma.governmentScheme.create({
        data: {
            title: data.title,
            titleMarathi: data.titleMarathi,
            titleHindi: data.titleHindi,
            description: data.description,
            ministry: data.ministry,
            benefits: data.benefits,
            eligibility: data.eligibility,
            documents: data.documents || [],
            applyUrl: data.applyUrl,
            deadline: data.deadline ? new Date(data.deadline) : null,
            isActive: data.isActive !== false,
        },
    });

    // Notify ALL farmers (Don't await)
    sendNotification({
        segments: ["Subscribed Users"], // or "Farmers" if mapped
        title: 'New Government Scheme 🏛️',
        message: `${scheme.title} is now available. Check eligibility!`,
        data: { schemeId: scheme.id, type: 'SCHEME' }
    });

    return scheme;
};

const updateScheme = async (id, data) => {
    return prisma.governmentScheme.update({
        where: { id },
        data: {
            title: data.title,
            titleMarathi: data.titleMarathi,
            description: data.description,
            ministry: data.ministry,
            benefits: data.benefits,
            eligibility: data.eligibility,
            documents: data.documents,
            applyUrl: data.applyUrl,
            deadline: data.deadline ? new Date(data.deadline) : undefined,
            isActive: data.isActive,
        },
    });
};

const deleteScheme = async (id) => {
    return prisma.governmentScheme.update({ where: { id }, data: { isActive: false } });
};

module.exports = { getSchemes, getScheme, getEligible, createScheme, updateScheme, deleteScheme };
