const mandiService = require('../services/mandi.service');
const { success } = require('../utils/apiResponse');

const getPrices = async (req, res, next) => {
    try { success(res, await mandiService.getPrices(req.query)); } catch (e) { next(e); }
};
const getCropHistory = async (req, res, next) => {
    try { success(res, await mandiService.getCropHistory(req.params.crop)); } catch (e) { next(e); }
};
const getNearbyMarkets = async (req, res, next) => {
    try { success(res, await mandiService.getNearbyMarkets(req.query)); } catch (e) { next(e); }
};

module.exports = { getPrices, getCropHistory, getNearbyMarkets };
