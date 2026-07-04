const prisma = require('../config/database');

/**
 * @desc    Get Mandi News (optionally filtered by district or state)
 * @route   GET /api/v1/news
 * @access  Public
 */
exports.getNews = async (req, res) => {
  try {
    const { district, state, limit = 20, page = 1 } = req.query;
    
    // Build filter query
    const where = {};
    if (district) {
      where.district = { contains: district, mode: 'insensitive' };
    } else if (state) {
      where.state = { contains: state, mode: 'insensitive' };
    }

    const skip = (Number(page) - 1) * Number(limit);

    // Fetch news
    const news = await prisma.mandiNews.findMany({
      where,
      orderBy: { publishedAt: 'desc' },
      take: Number(limit),
      skip,
    });

    // If no local news found, fallback to all general news
    if (news.length === 0 && (district || state)) {
      const fallbackNews = await prisma.mandiNews.findMany({
        orderBy: { publishedAt: 'desc' },
        take: Number(limit),
        skip,
      });
      return res.status(200).json({ success: true, data: fallbackNews, isFallback: true });
    }

    res.status(200).json({ success: true, data: news, isFallback: false });
  } catch (error) {
    console.error('Error fetching Mandi news:', error);
    res.status(500).json({ success: false, message: 'Server error fetching news' });
  }
};

/**
 * @desc    Create Mandi News (Admin only ideally)
 * @route   POST /api/v1/news
 */
exports.createNews = async (req, res) => {
  try {
    const { title, content, source, imageUrl, state, district, crop } = req.body;
    if (!title || !content) return res.status(400).json({ success: false, message: 'Title and content are required' });

    const news = await prisma.mandiNews.create({
      data: { title, content, source, imageUrl, state, district, crop }
    });

    res.status(201).json({ success: true, data: news });
  } catch (error) {
    console.error('Error creating Mandi news:', error);
    res.status(500).json({ success: false, message: 'Server error creating news' });
  }
};

