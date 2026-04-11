const prisma = require('../config/database');
const logger = require('../utils/logger');
const { getPagination } = require('../utils/helpers');
const { paginated } = require('../utils/apiResponse');

// Get all rates for the logged-in dealer
exports.getMyRates = async (req, res) => {
    try {
        const dealer = await prisma.dealer.findUnique({ where: { userId: req.user.id } });
        if (!dealer) return res.status(404).json({ message: 'Dealer profile not found' });

        const { page, limit, skip } = getPagination(req.query);

        const [rates, total] = await Promise.all([
            prisma.dealerCropRate.findMany({
                where: { dealerId: dealer.id },
                skip, take: limit,
                orderBy: { updatedAt: 'desc' }
            }),
            prisma.dealerCropRate.count({ where: { dealerId: dealer.id } })
        ]);
        
        paginated(res, rates, page, limit, total);
    } catch (error) {
        logger.error('Error in getMyRates:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Add or update a crop rate
exports.updateRate = async (req, res) => {
    try {
        const { cropName, pricePerQuintal, district, state, isActive } = req.body;
        const dealer = await prisma.dealer.findUnique({ where: { userId: req.user.id } });

        if (!dealer) return res.status(404).json({ message: 'Dealer profile not found' });

        const rate = await prisma.dealerCropRate.upsert({
            where: {
                dealerId_cropName_district: {
                    dealerId: dealer.id,
                    cropName,
                    district: district || dealer.district
                }
            },
            update: {
                pricePerQuintal: parseFloat(pricePerQuintal),
                isActive: isActive !== undefined ? isActive : true,
                state: state || dealer.state
            },
            create: {
                dealerId: dealer.id,
                cropName,
                pricePerQuintal: parseFloat(pricePerQuintal),
                district: district || dealer.district,
                state: state || dealer.state,
                isActive: isActive !== undefined ? isActive : true
            }
        });

        res.json({ rate });
    } catch (error) {
        logger.error('Error in updateRate:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Get bookings for the dealer
exports.getMyBookings = async (req, res) => {
    try {
        const dealer = await prisma.dealer.findUnique({ where: { userId: req.user.id } });
        if (!dealer) return res.status(404).json({ message: 'Dealer profile not found' });

        const { page, limit, skip } = getPagination(req.query);

        const [bookings, total] = await Promise.all([
            prisma.tradeBooking.findMany({
                where: { dealerId: dealer.id },
                skip, take: limit,
                include: { farmer: { include: { user: true } } },
                orderBy: { slotDate: 'asc' }
            }),
            prisma.tradeBooking.count({ where: { dealerId: dealer.id } })
        ]);
        
        paginated(res, bookings, page, limit, total);
    } catch (error) {
        logger.error('Error in getMyBookings:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Update booking status
exports.updateBookingStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        const booking = await prisma.tradeBooking.update({
            where: { id },
            data: { status }
        });

        res.json({ booking });
    } catch (error) {
        logger.error('Error in updateBookingStatus:', error);
        res.status(500).json({ message: 'Server error' });
    }
};
