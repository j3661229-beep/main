const prisma = require('../config/database');
const { uploadToSupabase } = require('../middleware/upload');
const { haversineDistance } = require('../utils/helpers');
const { sendNotification } = require('./onesignal.service');
const cache = require('../utils/cache');

const PRODUCT_CACHE_TTL = 120; // 2 minutes
const NEARBY_CACHE_TTL = 60;   // 1 minute for location queries

// ── Helpers ─────────────────────────────────────────────────
const toNumberOrNull = (v) => {
    if (v === undefined || v === null || v === '') return null;
    const n = parseFloat(v);
    return Number.isFinite(n) ? n : null;
};

/**
 * Approximate bounding box for lat/lng radius filtering (pushed to DB).
 * 1 degree latitude ≈ 111km. Longitude varies by cos(lat).
 */
const boundingBox = (lat, lng, radiusKm) => {
    const latDelta = radiusKm / 111;
    const lngDelta = radiusKm / (111 * Math.cos((lat * Math.PI) / 180));
    return {
        minLat: lat - latDelta,
        maxLat: lat + latDelta,
        minLng: lng - lngDelta,
        maxLng: lng + lngDelta,
    };
};

// Lean select for product cards (avoids over-fetching)
const PRODUCT_CARD_SELECT = {
    id: true,
    name: true,
    nameMarathi: true,
    nameHindi: true,
    description: true,
    category: true,
    price: true,
    unit: true,
    stockQuantity: true,
    images: true,
    isOrganic: true,
    brand: true,
    createdAt: true,
    supplier: {
        select: {
            id: true,
            businessName: true,
            district: true,
            latitude: true,
            longitude: true,
            rating: true,
            user: { select: { name: true } },
        },
    },
};

const withDistance = (products, lat, lng) => {
    if (lat === null || lng === null) {
        return products.map((p) => ({ ...p, supplierDistanceKm: null }));
    }
    return products.map((p) => {
        const sLat = p?.supplier?.latitude;
        const sLng = p?.supplier?.longitude;
        if (typeof sLat !== 'number' || typeof sLng !== 'number') {
            return { ...p, supplierDistanceKm: null };
        }
        const distance = haversineDistance(lat, lng, sLat, sLng);
        return { ...p, supplierDistanceKm: Number(distance.toFixed(2)) };
    });
};

// ── Main Queries ────────────────────────────────────────────
const getProducts = async ({ category, search, sort, district, lat, lng, radius = 50, page, limit, skip }) => {
    const userLat = toNumberOrNull(lat);
    const userLng = toNumberOrNull(lng);
    const radiusKm = toNumberOrNull(radius) ?? 50;

    // Round location for cache key (1 decimal ≈ 11km precision — good enough)
    const locKey = userLat !== null ? `${userLat.toFixed(1)}_${userLng.toFixed(1)}` : 'noLoc';
    const cacheKey = `products:v2:${category || 'all'}:${search || ''}:${district || ''}:${sort || 'new'}:${locKey}:${page}:${limit}`;

    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    // Build where clause
    const where = { isActive: true, isApproved: true, stockQuantity: { gt: 0 } };
    if (category) where.category = category.toUpperCase();
    if (search) {
        where.OR = [
            { name: { contains: search, mode: 'insensitive' } },
            { nameMarathi: { contains: search, mode: 'insensitive' } },
            { description: { contains: search, mode: 'insensitive' } },
        ];
    }

    // Bounding box pre-filter — push distance filtering into SQL instead of loading everything
    if (userLat !== null && userLng !== null) {
        const bbox = boundingBox(userLat, userLng, radiusKm);
        where.supplier = {
            ...(district ? { district: { contains: district, mode: 'insensitive' } } : {}),
            latitude: { gte: bbox.minLat, lte: bbox.maxLat },
            longitude: { gte: bbox.minLng, lte: bbox.maxLng },
        };
    } else if (district) {
        where.supplier = { district: { contains: district, mode: 'insensitive' } };
    }

    let products = await prisma.product.findMany({
        where,
        select: PRODUCT_CARD_SELECT,
        orderBy: sort === 'price_asc' ? { price: 'asc' } : sort === 'price_desc' ? { price: 'desc' } : { createdAt: 'desc' },
        take: 200, // Safety cap — never load more than 200 rows
    });

    products = withDistance(products, userLat, userLng);

    // Fine-grain haversine filter after bounding box
    if (userLat !== null && userLng !== null) {
        products = products.filter((p) => p.supplierDistanceKm === null || p.supplierDistanceKm <= radiusKm);
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
    const result = { products: paginatedProducts, total };

    await cache.set(cacheKey, result, PRODUCT_CACHE_TTL);
    return result;
};


const getProduct = async (id) => {
    const cacheKey = `product:detail:${id}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const product = await prisma.product.findUnique({
        where: { id },
        include: {
            supplier: {
                select: { id: true, businessName: true, district: true, latitude: true, longitude: true, rating: true, totalRatings: true, user: { select: { name: true, phone: true } } },
            },
            reviews: { take: 10, orderBy: { createdAt: 'desc' } },
        },
    });
    if (!product) throw Object.assign(new Error('Product not found'), { statusCode: 404 });

    await cache.set(cacheKey, product, PRODUCT_CACHE_TTL);
    return product;
};

const getNearby = async ({ lat, lng, radius = 25 }) => {
    const userLat = toNumberOrNull(lat);
    const userLng = toNumberOrNull(lng);
    const radiusKm = toNumberOrNull(radius) ?? 25;
    if (userLat === null || userLng === null) {
        throw Object.assign(new Error('lat and lng query params required'), { statusCode: 400 });
    }

    // Cache with rounded location
    const locKey = `${userLat.toFixed(1)}_${userLng.toFixed(1)}`;
    const cacheKey = `products:nearby:${locKey}:${radiusKm}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    // Bounding box pre-filter
    const bbox = boundingBox(userLat, userLng, radiusKm);

    const products = await prisma.product.findMany({
        where: {
            isActive: true, isApproved: true, stockQuantity: { gt: 0 },
            supplier: {
                latitude: { gte: bbox.minLat, lte: bbox.maxLat },
                longitude: { gte: bbox.minLng, lte: bbox.maxLng },
            },
        },
        select: PRODUCT_CARD_SELECT,
        take: 100,
    });

    const result = withDistance(products, userLat, userLng)
        .filter((p) => p.supplierDistanceKm !== null && p.supplierDistanceKm <= radiusKm)
        .sort((a, b) => a.supplierDistanceKm - b.supplierDistanceKm)
        .slice(0, 20);

    await cache.set(cacheKey, result, NEARBY_CACHE_TTL);
    return result;
};

const getNearbySuppliers = async ({ lat, lng, radius = 25, limit = 20 }) => {
    const userLat = toNumberOrNull(lat);
    const userLng = toNumberOrNull(lng);
    const radiusKm = toNumberOrNull(radius) ?? 25;
    const maxSuppliers = Math.min(50, Math.max(1, parseInt(limit, 10) || 20));
    if (userLat === null || userLng === null) {
        throw Object.assign(new Error('lat and lng query params required'), { statusCode: 400 });
    }

    const locKey = `${userLat.toFixed(1)}_${userLng.toFixed(1)}`;
    const cacheKey = `suppliers:nearby:${locKey}:${radiusKm}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    // Bounding box pre-filter
    const bbox = boundingBox(userLat, userLng, radiusKm);

    const suppliers = await prisma.supplier.findMany({
        where: {
            isVerified: true,
            latitude: { gte: bbox.minLat, lte: bbox.maxLat },
            longitude: { gte: bbox.minLng, lte: bbox.maxLng },
            products: { some: { isActive: true, isApproved: true, stockQuantity: { gt: 0 } } },
        },
        select: {
            id: true,
            businessName: true,
            district: true,
            latitude: true,
            longitude: true,
            rating: true,
            totalRatings: true,
            user: { select: { name: true } },
            products: {
                where: { isActive: true, isApproved: true, stockQuantity: { gt: 0 } },
                select: { id: true, name: true, price: true, images: true },
                take: 8,
                orderBy: { createdAt: 'desc' },
            },
        },
    });

    const result = suppliers
        .map((s) => {
            if (typeof s.latitude !== 'number' || typeof s.longitude !== 'number') return null;
            const distanceKm = Number(haversineDistance(userLat, userLng, s.latitude, s.longitude).toFixed(2));
            return { ...s, distanceKm };
        })
        .filter((s) => s !== null && s.distanceKm <= radiusKm)
        .sort((a, b) => a.distanceKm - b.distanceKm)
        .slice(0, maxSuppliers);

    await cache.set(cacheKey, result, NEARBY_CACHE_TTL);
    return result;
};

const getRecommended = async (farmerId) => {
    const cacheKey = `products:recommended:${farmerId}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const farmer = await prisma.farmer.findUnique({ where: { id: farmerId }, select: { latitude: true, longitude: true, soilType: true } });
    const where = { isActive: true, isApproved: true, stockQuantity: { gt: 0 } };
    if (farmer?.soilType) {
        where.OR = [
            { description: { contains: farmer.soilType.split(' ')[0], mode: 'insensitive' } },
        ];
    }

    // Bounding box if farmer has location
    if (farmer?.latitude && farmer?.longitude) {
        const bbox = boundingBox(farmer.latitude, farmer.longitude, 50);
        where.supplier = {
            latitude: { gte: bbox.minLat, lte: bbox.maxLat },
            longitude: { gte: bbox.minLng, lte: bbox.maxLng },
        };
    }

    const products = await prisma.product.findMany({
        where,
        take: 50,
        select: PRODUCT_CARD_SELECT,
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
    const result = withDistances.slice(0, 10);
    await cache.set(cacheKey, result, PRODUCT_CACHE_TTL);
    return result;
};

const invalidateProductCache = async () => {
    // Invalidate version key so stale caches refresh on next TTL expiry
    try {
        await cache.del('products:version');
    } catch (e) { /* ignore */ }
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

    await invalidateProductCache();

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
    const updated = await prisma.product.update({
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
    await invalidateProductCache();
    // Also invalidate product detail cache
    await cache.del(`product:detail:${productId}`);
    return updated;
};

const deleteProduct = async (supplierId, productId) => {
    const product = await prisma.product.findFirst({ where: { id: productId, supplierId } });
    if (!product) throw Object.assign(new Error('Product not found'), { statusCode: 404 });
    const result = await prisma.product.update({ where: { id: productId }, data: { isActive: false } });
    await invalidateProductCache();
    await cache.del(`product:detail:${productId}`);
    return result;
};


const uploadImages = async (supplierId, productId, files) => {
    const product = await prisma.product.findFirst({ where: { id: productId, supplierId } });
    if (!product) throw Object.assign(new Error('Product not found'), { statusCode: 404 });
    const urls = await Promise.all(files.map(f => uploadToSupabase(f.buffer, f.originalname, 'products')));
    const updated = await prisma.product.update({ where: { id: productId }, data: { images: [...product.images, ...urls] } });
    await cache.del(`product:detail:${productId}`);
    return updated;
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
    await cache.del(`product:detail:${productId}`);
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
