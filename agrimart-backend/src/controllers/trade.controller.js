const prisma = require('../config/database');
const logger = require('../utils/logger');
const { getPagination } = require('../utils/helpers');
const { paginated } = require('../utils/apiResponse');

// Fetch dealers for a district and crop
exports.getDealerRates = async (req, res) => {
    try {
        const { district, crop } = req.query;
        if (!district || !crop) {
            return res.status(400).json({ success: false, message: 'District and crop are required' });
        }

        const { page, limit, skip } = getPagination(req.query);
        const whereClause = {
            district: { equals: district, mode: 'insensitive' },
            cropName: { equals: crop, mode: 'insensitive' },
            isActive: true
        };

        const [rates, total] = await Promise.all([
            prisma.dealerCropRate.findMany({
                where: whereClause,
                skip, take: limit,
                include: {
                    supplier: {
                        include: { user: { select: { name: true, phone: true } } }
                    }
                },
                orderBy: { pricePerQuintal: 'desc' }
            }),
            prisma.dealerCropRate.count({ where: whereClause })
        ]);

        paginated(res, rates, page, limit, total);
    } catch (error) {
        logger.error(`Get dealer rates error: ${error.message}`);
        res.status(500).json({ success: false, message: error.message });
    }
};

// Book a trade slot
exports.bookTradeSlot = async (req, res) => {
    try {
        const { supplierId, cropName, approxQuintals, pricePerQuintal, slotDate, notes } = req.body;
        // The farmer ID is attached by auth middleware
        const userId = req.user.id;

        const farmer = await prisma.farmer.findUnique({ where: { userId } });
        if (!farmer) return res.status(404).json({ success: false, message: 'Farmer profile not found' });

        const booking = await prisma.tradeBooking.create({
            data: {
                farmerId: farmer.id,
                supplierId,
                cropName,
                approxQuintals: parseFloat(approxQuintals),
                pricePerQuintal: parseFloat(pricePerQuintal),
                slotDate: new Date(slotDate),
                notes
            }
        });

        res.status(201).json({ success: true, data: booking, message: 'Trade slot booked successfully' });
    } catch (error) {
        logger.error(`Book trade slot error: ${error.message}`);
        res.status(500).json({ success: false, message: error.message });
    }
};
