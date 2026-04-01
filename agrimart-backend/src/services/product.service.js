const prisma = require('../config/database');
const { uploadToSupabase } = require('../middleware/upload');
const { haversineDistance } = require('../utils/helpers');
const { sendNotification } = require('./onesignal.service');

const toNumberOrNull = (v) => {
    if (v === undefined || v === null || v === '') return null;
    const n = parseFloat(v);
    return Number.isFinite(n) ? n : null;
};

const withDistance = (products, lat, lng) => {
    if (lat === null || lng === null) {
        return products.map((p) => ({ ...p, supplierDistanceKm: null }));
    }
    return products
        .map((p) => {
            const sLat = p?.supplier?.latitude;
            const sLng = p?.supplier?.longitude;
            if (typeof sLat !== 'number' || typeof sLng !== 'number') {
                return { ...p, supplierDistanceKm: null };
            }
            const distance = haversineDistance(lat, lng, sLat, sLng);
            return { ...p, supplierDistanceKm: Number(distance.toFixed(2)) };
        });
};

const getProducts = async ({ category, search, sort, district, lat, lng, radius = 50, page, limit, skip }) => {
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

    const userLat = toNumberOrNull(lat);
    const userLng = toNumberOrNull(lng);
    const radiusKm = toNumberOrNull(radius) ?? 50;

    let products = await prisma.product.findMany({
        where,
        include: { supplier: { include: { user: true } } },
        orderBy: sort === 'price_asc' ? { price: 'asc' } : sort === 'price_desc' ? { price: 'desc' } : { createdAt: 'desc' }
    });

    products = withDistance(products, userLat, userLng);

    if (userLat !== null && userLng !== null) {
        products = products.filter((p) => p.supplierDistanceKm !== null && p.supplierDistanceKm <= radiusKm);
    }

    if (sort === 'nearest' && userLat !== null && userLng !== null) {
        products.sort((a, b) => {
            const ad = a.supplierDistanceKm ?? Number.POSITIVE_INFINITY;
            const bd = b.supplierDistanceKm ?? Number.POSITIVE_INFINITY;
            return ad - bd;
        });
    }

    const total = products.length;
    const paginatedProducts = products.slice(skip, skip + limit);

    return { products: paginatedProducts, total };
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
    const userLat = toNumberOrNull(lat);
    const userLng = toNumberOrNull(lng);
    const radiusKm = toNumberOrNull(radius) ?? 25;
    if (userLat === null || userLng === null) {
        throw Object.assign(new Error('lat and lng query params required'), { statusCode: 400 });
    }

    const products = await prisma.product.findMany({
        where: { isActive: true, isApproved: true, stockQuantity: { gt: 0 } },
        include: { supplier: { include: { user: true } } },
    });

    return withDistance(products, userLat, userLng)
        .filter((p) => p.supplierDistanceKm !== null && p.supplierDistanceKm <= radiusKm)
        .sort((a, b) => a.supplierDistanceKm - b.supplierDistanceKm)
        .slice(0, 20);
};

const getNearbySuppliers = async ({ lat, lng, radius = 25, limit = 20 }) => {
    const userLat = toNumberOrNull(lat);
    const userLng = toNumberOrNull(lng);
    const radiusKm = toNumberOrNull(radius) ?? 25;
    const maxSuppliers = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
    if (userLat === null || userLng === null) {
        throw Object.assign(new Error('lat and lng query params required'), { statusCode: 400 });
    }

    const suppliers = await prisma.supplier.findMany({
        where: {
            isVerified: true,
            products: { some: { isActive: true, isApproved: true, stockQuantity: { gt: 0 } } },
        },
        include: {
            user: true,
            products: {
                where: { isActive: true, isApproved: true, stockQuantity: { gt: 0 } },
                take: 8,
                orderBy: { createdAt: 'desc' },
            },
        },
    });

    return suppliers
        .map((s) => {
            if (typeof s.latitude !== 'number' || typeof s.longitude !== 'number') return null;
            const distanceKm = Number(haversineDistance(userLat, userLng, s.latitude, s.longitude).toFixed(2));
            return { ...s, distanceKm };
        })
        .filter((s) => s !== null && s.distanceKm <= radiusKm)
        .sort((a, b) => a.distanceKm - b.distanceKm)
        .slice(0, maxSuppliers);
};

const getRecommended = async (farmerId) => {
    const farmer = await prisma.farmer.findUnique({ where: { id: farmerId } });
    const where = { isActive: true, isApproved: true, stockQuantity: { gt: 0 } };
    if (farmer.soilType) {
        where.OR = [
            { description: { contains: farmer.soilType.split(' ')[0], mode: 'insensitive' } },
        ];
    }
    const products = await prisma.product.findMany({
        where,
        take: 50,
        include: { supplier: { include: { user: true } } },
        orderBy: { createdAt: 'desc' },
    });

    const withDistances = withDistance(products, farmer?.latitude ?? null, farmer?.longitude ?? null);
    if (farmer?.latitude && farmer?.longitude) {
        withDistances.sort((a, b) => {
            const ad = a.supplierDistanceKm ?? Number.POSITIVE_INFINITY;
            const bd = b.supplierDistanceKm ?? Number.POSITIVE_INFINITY;
            return ad - bd;
        });
    }
    return withDistances.slice(0, 10);
};

const createProduct = async (supplierId, data) => {
    const product = await prisma.product.create({
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
            images: data.images || [],
        },
        include: { supplier: true },
    });

    // Notify farmers in the same district (Don't await to keep response fast)
    prisma.farmer.findMany({
        where: { district: { contains: product.supplier.district, mode: 'insensitive' } },
        select: { userId: true }
    }).then(farmers => {
        if (farmers.length > 0) {
            sendNotification({
                users: farmers.map(f => f.userId),
                title: 'New Product in Your Region 🌾',
                message: `${product.name} is now available at ${product.supplier.businessName}!`,
                data: { productId: product.id, type: 'PRODUCT' }
            });
        }
    });

    return product;
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

module.exports = {
    getProducts,
    getProduct,
    getNearby,
    getNearbySuppliers,
    getRecommended,
    createProduct,
    updateProduct,
    deleteProduct,
    uploadImages,
    getReviews,
    addReview
};
