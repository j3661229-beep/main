const prisma = require('../config/database');
const { uploadToSupabase } = require('../middleware/upload');
const { haversineDistance } = require('../utils/helpers');

const getProducts = async ({ category, search, sort, district, page, limit, skip }) => {
    const where = { isActive: true, isApproved: true, stockQuantity: { gt: 0 } };
    if (category) where.category = category.toUpperCase();
    if (district) where.supplier = { district: { contains: district, mode: 'insensitive' } };
    if (search) {
        where.OR = [
            { name: { contains: search, mode: 'insensitive' } },
            { nameMarathi: { contains: search, mode: 'insensitive' } },
            { description: { contains: search, mode: 'insensitive' } },
        ];
    }
    const orderBy = sort === 'price_asc' ? { price: 'asc' } : sort === 'price_desc' ? { price: 'desc' } : { createdAt: 'desc' };
    const [products, total] = await Promise.all([
        prisma.product.findMany({ where, skip, take: limit, orderBy, include: { supplier: { include: { user: true } } } }),
        prisma.product.count({ where }),
    ]);
    return { products, total };
};

const getProduct = async (id) => {
    const product = await prisma.product.findUnique({
        where: { id },
        include: { supplier: { include: { user: true } }, reviews: { take: 10, orderBy: { createdAt: 'desc' } } },
    });
    if (!product) throw Object.assign(new Error('Product not found'), { statusCode: 404 });
    return product;
};

const getNearby = async ({ lat, lng, radius = 25 }) => {
    if (!lat || !lng) throw Object.assign(new Error('lat and lng query params required'), { statusCode: 400 });
    const products = await prisma.product.findMany({
        where: { isActive: true, isApproved: true, stockQuantity: { gt: 0 } },
        include: { supplier: { include: { user: true } } },
        take: 50,
    });
    return products
        .filter(p => p.supplier.latitude && p.supplier.longitude &&
            haversineDistance(parseFloat(lat), parseFloat(lng), p.supplier.latitude, p.supplier.longitude) <= parseFloat(radius))
        .slice(0, 20);
};

const getRecommended = async (farmerId) => {
    const farmer = await prisma.farmer.findUnique({ where: { id: farmerId } });
    const where = { isActive: true, isApproved: true, stockQuantity: { gt: 0 } };
    if (farmer.soilType) {
        where.OR = [
            { description: { contains: farmer.soilType.split(' ')[0], mode: 'insensitive' } },
        ];
    }
    return prisma.product.findMany({ where, take: 10, include: { supplier: { include: { user: true } } } });
};

const createProduct = async (supplierId, data) => {
    return prisma.product.create({
        data: {
            supplierId,
            name: data.name,
            nameMarathi: data.nameMarathi,
            nameHindi: data.nameHindi,
            description: data.description,
            category: data.category,
            price: parseFloat(data.price),
            unit: data.unit,
            stockQuantity: parseInt(data.stockQuantity),
            isOrganic: data.isOrganic === 'true' || data.isOrganic === true,
            brand: data.brand,
            composition: data.composition,
            usageInstructions: data.usageInstructions,
            images: [],
        },
        include: { supplier: true },
    });
};

const updateProduct = async (supplierId, productId, data) => {
    const product = await prisma.product.findFirst({ where: { id: productId, supplierId } });
    if (!product) throw Object.assign(new Error('Product not found'), { statusCode: 404 });
    return prisma.product.update({
        where: { id: productId },
        data: {
            name: data.name,
            nameMarathi: data.nameMarathi,
            description: data.description,
            price: data.price ? parseFloat(data.price) : undefined,
            unit: data.unit,
            stockQuantity: data.stockQuantity ? parseInt(data.stockQuantity) : undefined,
            isActive: data.isActive !== undefined ? data.isActive : undefined,
            isOrganic: data.isOrganic !== undefined ? data.isOrganic : undefined,
        },
    });
};

const deleteProduct = async (supplierId, productId) => {
    const product = await prisma.product.findFirst({ where: { id: productId, supplierId } });
    if (!product) throw Object.assign(new Error('Product not found'), { statusCode: 404 });
    return prisma.product.update({ where: { id: productId }, data: { isActive: false } });
};

const uploadImages = async (supplierId, productId, files) => {
    const product = await prisma.product.findFirst({ where: { id: productId, supplierId } });
    if (!product) throw Object.assign(new Error('Product not found'), { statusCode: 404 });
    const urls = await Promise.all(files.map(f => uploadToSupabase(f.buffer, f.originalname, 'products')));
    return prisma.product.update({ where: { id: productId }, data: { images: [...product.images, ...urls] } });
};

const getReviews = async (productId) => {
    return prisma.review.findMany({ where: { productId }, take: 20, orderBy: { createdAt: 'desc' } });
};

const addReview = async (farmerId, productId, { rating, comment, orderItemId }) => {
    const orderItem = await prisma.orderItem.findFirst({ where: { id: orderItemId, order: { farmerId }, status: 'DELIVERED' } });
    if (!orderItem) throw Object.assign(new Error('Can only review verified purchases'), { statusCode: 403 });
    const exists = await prisma.review.findUnique({ where: { orderItemId } });
    if (exists) throw Object.assign(new Error('Already reviewed this item'), { statusCode: 409 });

    const review = await prisma.review.create({
        data: { orderItemId, productId, farmerId, rating: parseInt(rating), comment },
    });
    // Update supplier rating
    const allReviews = await prisma.review.findMany({ where: { product: { supplierId: orderItem.supplierId } }, select: { rating: true } });
    const avgRating = allReviews.reduce((s, r) => s + r.rating, 0) / allReviews.length;
    await prisma.supplier.update({ where: { id: orderItem.supplierId }, data: { rating: avgRating, totalRatings: allReviews.length } });
    return review;
};

module.exports = { getProducts, getProduct, getNearby, getRecommended, createProduct, updateProduct, deleteProduct, uploadImages, getReviews, addReview };
