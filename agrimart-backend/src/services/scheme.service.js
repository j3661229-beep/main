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
    if (!farmerId) return [];
    const farmer = await prisma.farmer.findUnique({ where: { id: farmerId } });
    if (!farmer) return [];

    const schemes = await prisma.governmentScheme.findMany({
        where: { isActive: true },
        orderBy: { createdAt: 'desc' },
    });

    const district = (farmer.district || '').toLowerCase();
    const state = (farmer.state || 'maharashtra').toLowerCase();
    const landSize = farmer.farmSizeAcres || 0;
    const crops = (farmer.currentCrops || []).map((c) => c.toLowerCase());

    const scoreScheme = (scheme) => {
        const blob = `${scheme.title} ${scheme.eligibility} ${scheme.description} ${scheme.benefits}`.toLowerCase();
        let score = 0;
        if (blob.includes('farmer') || blob.includes('kisan')) score += 2;
        if (district && blob.includes(district)) score += 3;
        if (blob.includes(state) || blob.includes('maharashtra')) score += 1;
        if (landSize > 0 && landSize <= 2 && (blob.includes('small') || blob.includes('marginal'))) score += 2;
        if (landSize > 2 && landSize <= 5 && blob.includes('small')) score += 1;
        for (const crop of crops) {
            const token = crop.split(' ')[0];
            if (token.length > 2 && blob.includes(token)) score += 2;
        }
        if (blob.includes('pm-kisan') || blob.includes('pm kisan')) score += 3;
        if (blob.includes('pmfby') || blob.includes('crop insurance')) score += 2;
        return score;
    };

    return schemes
        .map((scheme) => ({ ...scheme, matchScore: scoreScheme(scheme) }))
        .filter((s) => s.matchScore >= 2)
        .sort((a, b) => b.matchScore - a.matchScore)
        .slice(0, 15);
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
