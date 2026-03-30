const aiService = require('../services/ai.service');
const { success } = require('../utils/apiResponse');

const soilAnalysis = async (req, res, next) => {
    try {
        if (!req.file) return res.status(400).json({ success: false, message: 'Image file required' });
        const data = await aiService.soilAnalysis(req.user.farmer?.id, req.file.buffer, req.file.originalname, req.body.location);
        success(res, data);
    } catch (e) { next(e); }
};

const diseaseDetection = async (req, res, next) => {
    try {
        if (!req.file) return res.status(400).json({ success: false, message: 'Image file required' });
        const data = await aiService.diseaseDetection(req.file.buffer, req.file.originalname);
        success(res, data);
    } catch (e) { next(e); }
};

const cropRecommend = async (req, res, next) => {
    try {
        const data = await aiService.cropRecommend(req.user.farmer?.id, req.body);
        success(res, data);
    } catch (e) { next(e); }
};

const chat = async (req, res, next) => {
    try {
        const data = await aiService.chat(req.user.id, req.body);
        success(res, data);
    } catch (e) { next(e); }
};

const cropCalendar = async (req, res, next) => {
    try {
        const data = await aiService.cropCalendar(req.query);
        success(res, data);
    } catch (e) { next(e); }
};

module.exports = { soilAnalysis, diseaseDetection, cropRecommend, chat, cropCalendar };
