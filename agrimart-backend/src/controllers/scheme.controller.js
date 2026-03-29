const schemeService = require('../services/scheme.service');
const { success, created } = require('../utils/apiResponse');

const getSchemes = async (req, res, next) => { try { success(res, await schemeService.getSchemes(req.query)); } catch (e) { next(e); } };
const getScheme = async (req, res, next) => { try { success(res, await schemeService.getScheme(req.params.id)); } catch (e) { next(e); } };
const getEligible = async (req, res, next) => { try { success(res, await schemeService.getEligible(req.user.farmer?.id)); } catch (e) { next(e); } };

module.exports = { getSchemes, getScheme, getEligible };
