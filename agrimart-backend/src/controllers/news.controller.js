const newsService = require('../services/news.service');

/**
 * @desc    Get Mandi News (DB + Google News RSS, location-aware)
 * @route   GET /api/news
 */
exports.getNews = async (req, res) => {
    try {
        const { district, state, limit = 20, page = 1, google } = req.query;
        const result = await newsService.getNews({
            district,
            state,
            limit,
            page,
            includeGoogle: google !== 'false',
        });

        res.status(200).json({
            success: true,
            data: result.items,
            scope: result.scope,
            isFallback: result.isFallback,
            sourceMix: result.sourceMix,
        });
    } catch (error) {
        console.error('Error fetching Mandi news:', error);
        res.status(500).json({ success: false, message: 'Server error fetching news' });
    }
};

/**
 * @desc    Create Mandi News manually
 * @route   POST /api/news
 */
exports.createNews = async (req, res) => {
    try {
        const { title, content, source, imageUrl, state, district, crop } = req.body;
        if (!title || !content) {
            return res.status(400).json({ success: false, message: 'Title and content are required' });
        }

        const news = await newsService.createManualNews({
            title, content, source, imageUrl, state, district, crop,
        });

        res.status(201).json({ success: true, data: news });
    } catch (error) {
        console.error('Error creating Mandi news:', error);
        res.status(500).json({ success: false, message: 'Server error creating news' });
    }
};

/**
 * @desc    Sync Google News RSS into database
 * @route   POST /api/news/sync
 */
exports.syncGoogleNews = async (req, res) => {
    try {
        const { districts } = req.body || {};
        const locations = Array.isArray(districts) && districts.length > 0
            ? districts
            : newsService.DEFAULT_DISTRICTS;

        const result = await newsService.syncGoogleNewsToDb(locations);
        res.status(200).json({ success: true, message: 'Google News RSS synced', ...result });
    } catch (error) {
        console.error('Error syncing Google News RSS:', error);
        res.status(500).json({ success: false, message: 'RSS sync failed' });
    }
};
