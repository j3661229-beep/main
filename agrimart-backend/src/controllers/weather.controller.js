const weatherService = require('../services/weather.service');
const { success } = require('../utils/apiResponse');

const getCurrent = async (req, res, next) => {
    try { success(res, await weatherService.getCurrent(req.query)); } catch (e) { next(e); }
};
const getForecast = async (req, res, next) => {
    try { success(res, await weatherService.getForecast(req.query)); } catch (e) { next(e); }
};
const getAdvisory = async (req, res, next) => {
    try { success(res, await weatherService.getAdvisory(req.query)); } catch (e) { next(e); }
};

module.exports = { getCurrent, getForecast, getAdvisory };
