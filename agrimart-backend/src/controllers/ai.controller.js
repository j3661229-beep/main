const aiService = require('../services/ai.service');
const { success, error } = require('../utils/apiResponse');
const { optimizeAiImage } = require('../utils/imageOptimize.util');
const prisma = require('../config/database');

const resolveFarmerId = async (req, res) => {
    const directId = req.user?.farmer?.id;
    if (directId) return directId;
    const farmer = await prisma.farmer.findUnique({ where: { userId: req.user.id } });
    if (!farmer) {
        error(res, 'Farmer profile required. Please complete your profile setup first.', 403);
        return null;
    }
    return farmer.id;
};

const soilAnalysis = async (req, res, next) => {
    try {
        if (!req.file) return res.status(400).json({ success: false, message: 'Image file required' });
        const farmerId = await resolveFarmerId(req, res);
        if (!farmerId) return;
        const { location, language } = req.body;
        const { buffer, ext } = await optimizeAiImage(req.file.buffer);
        const data = await aiService.soilAnalysis(farmerId, buffer, `soil.${ext}`, {
            location, language, userId: req.user.id,
        });
        success(res, data);
    } catch (e) { next(e); }
};

const diseaseDetection = async (req, res, next) => {
    try {
        if (!req.file) return res.status(400).json({ success: false, message: 'Image file required' });
        const farmerId = await resolveFarmerId(req, res);
        if (!farmerId) return;
        const { language } = req.body;
        const { buffer, ext } = await optimizeAiImage(req.file.buffer);
        const data = await aiService.diseaseDetection(buffer, `crop.${ext}`, {
            language, userId: req.user.id,
        });
        success(res, data);
    } catch (e) { next(e); }
};

const cropRecommend = async (req, res, next) => {
    try {
        const farmerId = await resolveFarmerId(req, res);
        if (!farmerId) return;
        const data = await aiService.cropRecommend(farmerId, { ...req.body, userId: req.user.id });
        success(res, data);
    } catch (e) { next(e); }
};

const chat = async (req, res, next) => {
    try {
        const { message, history, language } = req.body;
        if (!req.user?.farmer && req.user?.role === 'FARMER') {
            const farmer = await prisma.farmer.findUnique({ where: { userId: req.user.id } });
            if (!farmer) return error(res, 'Farmer profile required. Complete farm setup first.', 403);
        }
        const data = await aiService.chat(req.user.id, { message, history, language });
        success(res, data);
    } catch (e) { next(e); }
};

const cropCalendar = async (req, res, next) => {
    try {
        if (!req.user?.id) return error(res, 'Login required.', 401);
        const data = await aiService.cropCalendar({
            month: req.query.month,
            language: req.query.language || req.body?.language,
            userId: req.user.id,
        });
        success(res, data);
    } catch (e) { next(e); }
};

const getDiagnoseHistory = async (req, res, next) => {
    try {
        const farmerId = await resolveFarmerId(req, res);
        if (!farmerId) return;
        const data = await aiService.getDiagnoseHistory(farmerId, req.query);
        success(res, data);
    } catch (e) { next(e); }
};

module.exports = { soilAnalysis, diseaseDetection, cropRecommend, chat, cropCalendar, getDiagnoseHistory };
