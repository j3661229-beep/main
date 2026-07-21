const prisma = require('../config/database');
const { sendNotification } = require('./onesignal.service');

const VALID_TRADE_STATUSES = ['PENDING', 'ACCEPTED', 'COMPLETED', 'CANCELLED'];

const VALID_TRANSITIONS = {
    PENDING: ['ACCEPTED', 'CANCELLED'],
    ACCEPTED: ['COMPLETED', 'CANCELLED'],
    COMPLETED: [],
    CANCELLED: [],
};

const formatBooking = (b) => ({
    ...b,
    farmerName: b.farmer?.user?.name ?? 'Farmer',
    crop: b.cropName,
    quantity: b.approxQuintals,
    offerPrice: b.pricePerQuintal,
    pickupDate: b.slotDate,
});

const getProfile = async (dealerId) => {
    return prisma.dealer.findUnique({ where: { id: dealerId }, include: { user: true } });
};

const updateProfile = async (dealerId, data) => {
    const dealer = await prisma.dealer.findUnique({ where: { id: dealerId } });
    if (!dealer) throw Object.assign(new Error('Dealer profile not found'), { statusCode: 404 });

    if (data.name || data.language) {
        await prisma.user.update({
            where: { id: dealer.userId },
            data: { name: data.name, language: data.language },
        });
    }

    return prisma.dealer.update({
        where: { id: dealerId },
        data: {
            businessName: data.businessName,
            address: data.address,
            district: data.district,
            state: data.state,
            pincode: data.pincode,
            latitude: data.latitude != null ? parseFloat(data.latitude) : undefined,
            longitude: data.longitude != null ? parseFloat(data.longitude) : undefined,
        },
        include: { user: true },
    });
};

const getDashboard = async (dealerId) => {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const todayEnd = new Date(todayStart);
    todayEnd.setDate(todayEnd.getDate() + 1);

    const [
        rates,
        bookings,
        activeRates,
        pendingBookings,
        activeDeals,
        todaySlots,
        monthBookings,
        totalBookings,
    ] = await Promise.all([
        prisma.dealerCropRate.findMany({
            where: { dealerId, isActive: true },
            orderBy: { updatedAt: 'desc' },
            take: 20,
        }),
        prisma.tradeBooking.findMany({
            where: { dealerId },
            take: 10,
            orderBy: { createdAt: 'desc' },
            include: { farmer: { include: { user: true } } },
        }),
        prisma.dealerCropRate.count({ where: { dealerId, isActive: true } }),
        prisma.tradeBooking.count({ where: { dealerId, status: 'PENDING' } }),
        prisma.tradeBooking.count({ where: { dealerId, status: 'ACCEPTED' } }),
        prisma.tradeBooking.count({
            where: {
                dealerId,
                slotDate: { gte: todayStart, lt: todayEnd },
                status: { in: ['PENDING', 'ACCEPTED'] },
            },
        }),
        prisma.tradeBooking.findMany({
            where: { dealerId, createdAt: { gte: monthStart } },
            select: { approxQuintals: true, pricePerQuintal: true },
        }),
        prisma.tradeBooking.count({ where: { dealerId } }),
    ]);

    const volumeThisMonth = monthBookings.reduce((s, b) => s + (b.approxQuintals || 0), 0);
    const dealValues = monthBookings.map((b) => (b.approxQuintals || 0) * (b.pricePerQuintal || 0));
    const avgDealSize = dealValues.length
        ? dealValues.reduce((a, b) => a + b, 0) / dealValues.length
        : 0;

    const formattedBookings = bookings.map(formatBooking);

    return {
        activeRates,
        pendingBookings,
        activeDeals,
        todaySlots,
        totalBookings,
        volumeThisMonth,
        avgDealSize: Math.round(avgDealSize),
        pendingPickups: pendingBookings,
        rates,
        bookings: formattedBookings,
        recentBookings: formattedBookings,
    };
};

const getRates = async (dealerId, { page, limit, skip }) => {
    const where = { dealerId };
    const [rates, total] = await Promise.all([
        prisma.dealerCropRate.findMany({
            where, skip, take: limit,
            orderBy: { updatedAt: 'desc' },
        }),
        prisma.dealerCropRate.count({ where }),
    ]);
    return { rates, total };
};

const upsertRate = async (dealerId, data) => {
    const { cropName, pricePerQuintal, district, state, isActive } = data;
    if (!cropName?.trim()) {
        throw Object.assign(new Error('cropName is required'), { statusCode: 400 });
    }
    if (pricePerQuintal == null || isNaN(parseFloat(pricePerQuintal)) || parseFloat(pricePerQuintal) <= 0) {
        throw Object.assign(new Error('Valid pricePerQuintal is required'), { statusCode: 400 });
    }

    const dealer = await prisma.dealer.findUnique({ where: { id: dealerId } });
    if (!dealer) throw Object.assign(new Error('Dealer profile not found'), { statusCode: 404 });

    const rateDistrict = district?.trim() || dealer.district;

    return prisma.dealerCropRate.upsert({
        where: {
            dealerId_cropName_district: {
                dealerId,
                cropName: cropName.trim(),
                district: rateDistrict,
            },
        },
        update: {
            pricePerQuintal: parseFloat(pricePerQuintal),
            isActive: isActive !== undefined ? isActive : true,
            state: state || dealer.state,
        },
        create: {
            dealerId,
            cropName: cropName.trim(),
            pricePerQuintal: parseFloat(pricePerQuintal),
            district: rateDistrict,
            state: state || dealer.state,
            isActive: isActive !== undefined ? isActive : true,
        },
    });
};

const deactivateRate = async (dealerId, rateId) => {
    const rate = await prisma.dealerCropRate.findFirst({ where: { id: rateId, dealerId } });
    if (!rate) throw Object.assign(new Error('Rate not found'), { statusCode: 404 });
    return prisma.dealerCropRate.update({ where: { id: rateId }, data: { isActive: false } });
};

const getBookings = async (dealerId, { page, limit, skip }, filters) => {
    const where = { dealerId };
    if (filters.status) where.status = filters.status.toUpperCase();
    if (filters.crop && filters.crop !== 'All') {
        where.cropName = { contains: filters.crop, mode: 'insensitive' };
    }

    const [bookings, total] = await Promise.all([
        prisma.tradeBooking.findMany({
            where, skip, take: limit,
            include: { farmer: { include: { user: true } } },
            orderBy: { slotDate: 'asc' },
        }),
        prisma.tradeBooking.count({ where }),
    ]);

    return { bookings: bookings.map(formatBooking), total };
};

const getBooking = async (dealerId, bookingId) => {
    const booking = await prisma.tradeBooking.findFirst({
        where: { id: bookingId, dealerId },
        include: { farmer: { include: { user: true } } },
    });
    if (!booking) throw Object.assign(new Error('Booking not found'), { statusCode: 404 });
    return formatBooking(booking);
};

const updateBookingStatus = async (dealerId, bookingId, status, extra = {}) => {
    const normalized = status?.toUpperCase();
    if (!VALID_TRADE_STATUSES.includes(normalized)) {
        throw Object.assign(new Error(`Invalid status. Allowed: ${VALID_TRADE_STATUSES.join(', ')}`), { statusCode: 400 });
    }

    const booking = await prisma.tradeBooking.findFirst({
        where: { id: bookingId, dealerId },
        include: { farmer: { include: { user: true } } },
    });
    if (!booking) throw Object.assign(new Error('Booking not found'), { statusCode: 404 });

    if (!VALID_TRANSITIONS[booking.status]?.includes(normalized)) {
        throw Object.assign(new Error(`Cannot transition from ${booking.status} to ${normalized}`), { statusCode: 400 });
    }

    const updateData = { status: normalized };
    if (extra.notes != null) updateData.notes = extra.notes;
    if (normalized === 'ACCEPTED' && extra.offerPrice != null) {
        updateData.pricePerQuintal = parseFloat(extra.offerPrice);
    }

    const updated = await prisma.tradeBooking.update({
        where: { id: bookingId },
        data: updateData,
        include: { farmer: { include: { user: true } } },
    });

    if (updated.farmer?.user?.id) {
        const statusLabels = {
            ACCEPTED: 'accepted',
            COMPLETED: 'marked as completed',
            CANCELLED: 'cancelled',
        };
        const label = statusLabels[normalized] || normalized.toLowerCase();
        const title = `Booking ${normalized}`;
        const message = `Your ${updated.cropName} delivery slot was ${label} by the dealer`;

        sendNotification({
            users: [updated.farmer.user.id],
            title,
            message,
            data: { type: 'TRADE_BOOKING', bookingId: updated.id, status: normalized },
        });

        const notifService = require('./notification.service');
        await notifService.createNotification(updated.farmer.user.id, {
            title,
            body: message,
            type: 'TRADE',
            data: { bookingId: updated.id, status: normalized },
        });
    }

    return formatBooking(updated);
};

module.exports = {
    getProfile,
    updateProfile,
    getDashboard,
    getRates,
    upsertRate,
    deactivateRate,
    getBookings,
    getBooking,
    updateBookingStatus,
};
