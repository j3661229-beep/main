const prisma = require('../config/database');
const logger = require('../utils/logger');
const cache = require('../utils/cache');
const { getPagination } = require('../utils/helpers');
const { paginated } = require('../utils/apiResponse');
const { sendNotification } = require('../services/onesignal.service');

const RATES_CACHE_TTL = 300;

// Fetch dealers for a district (and optionally a specific crop)
exports.getDealerRates = async (req, res) => {
    try {
        const { district, crop } = req.query;
        if (!district) {
            return res.status(400).json({ success: false, message: 'District is required' });
        }

        const { page, limit, skip } = getPagination(req.query);
        const cacheKey = `trade:rates:${district.toLowerCase()}:${crop || 'all'}:${page}:${limit}`;
        const cached = await cache.get(cacheKey);
        if (cached) return res.json(cached);

        const whereClause = {
            district: { equals: district, mode: 'insensitive' },
            isActive: true,
            dealer: { isVerified: true, docStatus: 'APPROVED' },
            ...(crop ? { cropName: { equals: crop, mode: 'insensitive' } } : {}),
        };

        const [rates, total] = await Promise.all([
            prisma.dealerCropRate.findMany({
                where: whereClause,
                skip, take: limit,
                select: {
                    id: true, cropName: true, pricePerQuintal: true, district: true, dealerId: true,
                    dealer: { select: { id: true, businessName: true, user: { select: { name: true } } } },
                },
                orderBy: { pricePerQuintal: 'desc' },
            }),
            prisma.dealerCropRate.count({ where: whereClause }),
        ]);

        const payload = { success: true, data: rates, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) } };
        await cache.set(cacheKey, payload, RATES_CACHE_TTL);
        res.json(payload);
    } catch (error) {
        logger.error(`Get dealer rates error: ${error.message}`);
        res.status(500).json({ success: false, message: error.message });
    }
};


// Book a trade slot
exports.bookTradeSlot = async (req, res) => {
    try {
        const { dealerId, cropName, approxQuintals, pricePerQuintal, slotDate, notes } = req.body;
        // The farmer ID is attached by auth middleware
        const userId = req.user.id;

        const farmer = await prisma.farmer.findUnique({ where: { userId }, include: { user: true } });
        if (!farmer) return res.status(404).json({ success: false, message: 'Farmer profile not found' });

        const dealer = await prisma.dealer.findFirst({
            where: { id: dealerId, isVerified: true, docStatus: 'APPROVED' },
            include: { user: { select: { id: true, name: true } } },
        });
        if (!dealer) {
            return res.status(400).json({ success: false, message: 'Dealer not found or not verified' });
        }

        const booking = await prisma.tradeBooking.create({
            data: {
                farmerId: farmer.id,
                dealerId: dealer.id,
                cropName,
                approxQuintals: parseFloat(approxQuintals),
                pricePerQuintal: parseFloat(pricePerQuintal),
                slotDate: new Date(slotDate),
                notes
            },
            include: {
                dealer: { include: { user: { select: { id: true, name: true } } } },
            },
        });

        if (booking.dealer?.user?.id) {
            sendNotification({
                users: [booking.dealer.user.id],
                title: '🌾 New produce booking',
                message: `${farmer.user?.name || 'A farmer'} booked ${cropName} — ${approxQuintals} qtl @ ₹${pricePerQuintal}/qtl`,
                data: { type: 'TRADE_BOOKING', bookingId: booking.id },
            });
        }

        res.status(201).json({ success: true, data: booking, message: 'Trade slot booked successfully' });
    } catch (error) {
        logger.error(`Book trade slot error: ${error.message}`);
        res.status(500).json({ success: false, message: error.message });
    }
};

// Get trade bookings for the logged-in farmer
exports.getFarmerBookings = async (req, res) => {
    try {
        const userId = req.user.id;
        const farmer = await prisma.farmer.findUnique({ where: { userId } });
        if (!farmer) return res.status(404).json({ success: false, message: 'Farmer profile not found' });

        const { page, limit, skip } = getPagination(req.query);

        const [bookings, total] = await Promise.all([
            prisma.tradeBooking.findMany({
                where: { farmerId: farmer.id },
                skip, take: limit,
                include: {
                    dealer: {
                        include: { user: { select: { name: true, phone: true } } }
                    }
                },
                orderBy: { createdAt: 'desc' }
            }),
            prisma.tradeBooking.count({ where: { farmerId: farmer.id } })
        ]);

        paginated(res, bookings, page, limit, total);
    } catch (error) {
        logger.error(`Get farmer bookings error: ${error.message}`);
        res.status(500).json({ success: false, message: error.message });
    }
};
