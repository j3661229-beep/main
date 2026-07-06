const dealerService = require('../services/dealer.service');
const { success, paginated } = require('../utils/apiResponse');
const { getPagination } = require('../utils/helpers');
const prisma = require('../config/database');

const resolveDealer = async (req) => {
    const directId = req.user?.dealer?.id;
    if (directId) return directId;
    const d = await prisma.dealer.findUnique({ where: { userId: req.user.id } });
    if (!d) throw Object.assign(new Error('Dealer profile not found. Please complete onboarding.'), { statusCode: 404 });
    return d.id;
};

const getProfile = async (req, res, next) => {
    try { success(res, await dealerService.getProfile(await resolveDealer(req))); } catch (e) { next(e); }
};

const updateProfile = async (req, res, next) => {
    try { success(res, await dealerService.updateProfile(await resolveDealer(req), req.body), 'Profile updated'); } catch (e) { next(e); }
};

const getDashboard = async (req, res, next) => {
    try { success(res, await dealerService.getDashboard(await resolveDealer(req))); } catch (e) { next(e); }
};

const getMyRates = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { rates, total } = await dealerService.getRates(await resolveDealer(req), pag);
        paginated(res, rates, pag.page, pag.limit, total);
    } catch (e) { next(e); }
};

const updateRate = async (req, res, next) => {
    try {
        const rate = await dealerService.upsertRate(await resolveDealer(req), req.body);
        success(res, { rate }, 'Rate saved');
    } catch (e) { next(e); }
};

const deleteRate = async (req, res, next) => {
    try {
        success(res, await dealerService.deactivateRate(await resolveDealer(req), req.params.id), 'Rate deactivated');
    } catch (e) { next(e); }
};

const getMyBookings = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { bookings, total } = await dealerService.getBookings(await resolveDealer(req), pag, req.query);
        paginated(res, bookings, pag.page, pag.limit, total);
    } catch (e) { next(e); }
};

const getBooking = async (req, res, next) => {
    try { success(res, await dealerService.getBooking(await resolveDealer(req), req.params.id)); } catch (e) { next(e); }
};

const updateBookingStatus = async (req, res, next) => {
    try {
        const booking = await dealerService.updateBookingStatus(
            await resolveDealer(req),
            req.params.id,
            req.body.status,
            req.body,
        );
        success(res, { booking }, 'Booking updated');
    } catch (e) { next(e); }
};

module.exports = {
    getProfile,
    updateProfile,
    getDashboard,
    getMyRates,
    updateRate,
    deleteRate,
    getMyBookings,
    getBooking,
    updateBookingStatus,
};
