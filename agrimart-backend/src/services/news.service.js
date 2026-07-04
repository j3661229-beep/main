const axios = require('axios');
const { XMLParser } = require('fast-xml-parser');
const prisma = require('../config/database');
const redis = require('../config/redis');
const logger = require('../utils/logger');

const RSS_CACHE_TTL = 1800; // 30 minutes
const NEWS_CACHE_TTL = 600; // 10 minutes

const DEFAULT_DISTRICTS = [
    { district: 'Nashik', state: 'Maharashtra' },
    { district: 'Pune', state: 'Maharashtra' },
    { district: 'Nagpur', state: 'Maharashtra' },
    { district: 'Kolhapur', state: 'Maharashtra' },
    { district: 'Aurangabad', state: 'Maharashtra' },
];

const CROP_KEYWORDS = [
    'onion', 'tomato', 'grapes', 'grape', 'wheat', 'soybean', 'cotton',
    'sugarcane', 'maize', 'chilli', 'potato', 'pomegranate', 'mango',
    'rice', 'pulses', 'tur', 'moong', 'urad', 'mustard', 'groundnut',
];

const safeRedisGet = async (key) => {
    try {
        return await redis.get(key);
    } catch (err) {
        logger.warn(`Redis get failed (${key}): ${err.message}`);
        return null;
    }
};

const safeRedisSet = async (key, ttl, value) => {
    try {
        redis.setWithExpiry(key, ttl, value).catch(() => {});
    } catch (err) {
        logger.warn(`Redis set failed (${key}): ${err.message}`);
    }
};

const xmlParser = new XMLParser({
    ignoreAttributes: false,
    attributeNamePrefix: '@_',
});

const stripHtml = (html = '') =>
    html.replace(/<!\[CDATA\[|\]\]>/g, '').replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();

const extractImage = (html = '') => {
    const match = html.match(/src=["']([^"']+)["']/i);
    return match?.[1] ?? null;
};

const parsePubDate = (pubDate) => {
    if (!pubDate) return new Date();
    const d = new Date(pubDate);
    return Number.isNaN(d.getTime()) ? new Date() : d;
};

const detectCrop = (text = '') => {
    const lower = text.toLowerCase();
    const hit = CROP_KEYWORDS.find((crop) => lower.includes(crop));
    if (!hit) return null;
    return hit.charAt(0).toUpperCase() + hit.slice(1);
};

const buildGoogleNewsRssUrl = (query) => {
    const params = new URLSearchParams({
        q: query,
        hl: 'en-IN',
        gl: 'IN',
        ceid: 'IN:en',
    });
    return `https://news.google.com/rss/search?${params.toString()}`;
};

const normalizeItems = (rawItems) => {
    const list = Array.isArray(rawItems) ? rawItems : rawItems ? [rawItems] : [];
    return list.map((item) => {
        const title = stripHtml(item.title || '');
        const description = stripHtml(item.description || item.summary || '');
        const link = item.link || item.guid || null;
        const source = item.source?.['#text'] || item.source || 'Google News';
        const publishedAt = parsePubDate(item.pubDate);

        return {
            title,
            content: description || title,
            source: typeof source === 'string' ? source : 'Google News',
            imageUrl: extractImage(item.description || ''),
            publishedAt,
            link,
            crop: detectCrop(`${title} ${description}`),
            isExternal: true,
        };
    }).filter((item) => item.title.length > 0);
};

const fetchGoogleNewsRss = async (query) => {
    const cacheKey = `google_rss:${query}`;
    const cached = await safeRedisGet(cacheKey);
    if (cached) return cached;

    const url = buildGoogleNewsRssUrl(query);
    const { data: xml } = await axios.get(url, {
        timeout: 15000,
        headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            Accept: 'application/rss+xml, application/xml, text/xml, */*',
        },
    });

    const parsed = xmlParser.parse(xml);
    const items = normalizeItems(parsed?.rss?.channel?.item);
    await safeRedisSet(cacheKey, RSS_CACHE_TTL, items);
    return items;
};

const buildLocationQueries = ({ district, state }) => {
    const queries = [];
    if (district && state) {
        queries.push(`${district} agriculture mandi farmer crop ${state} India when:14d`);
        queries.push(`${district} ${state} farmer crop market when:14d`);
    } else if (state) {
        queries.push(`agriculture mandi farmer ${state} India when:14d`);
    }
    queries.push('agriculture mandi farmer crop India when:7d');
    return [...new Set(queries)];
};

const tagLocation = (items, { district, state }) =>
    items.map((item) => ({
        ...item,
        district: district || item.district || null,
        state: state || item.state || 'Maharashtra',
    }));

const dedupeByTitle = (items) => {
    const seen = new Set();
    return items.filter((item) => {
        const key = item.title.toLowerCase().trim();
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
    });
};

const mapDbArticle = (row) => ({
    id: row.id,
    title: row.title,
    content: row.content,
    source: row.source,
    imageUrl: row.imageUrl,
    state: row.state,
    district: row.district,
    crop: row.crop,
    publishedAt: row.publishedAt,
    createdAt: row.createdAt,
    isExternal: false,
});

const fetchDbNews = async ({ district, state, take, skip }) => {
    const orderBy = { publishedAt: 'desc' };

    if (district) {
        const local = await prisma.mandiNews.findMany({
            where: { district: { contains: district, mode: 'insensitive' } },
            orderBy,
            take,
            skip,
        });
        if (local.length > 0) {
            return { items: local.map(mapDbArticle), scope: 'district', isFallback: false };
        }
    }

    if (state) {
        const stateNews = await prisma.mandiNews.findMany({
            where: { state: { contains: state, mode: 'insensitive' } },
            orderBy,
            take,
            skip,
        });
        if (stateNews.length > 0) {
            return { items: stateNews.map(mapDbArticle), scope: 'state', isFallback: false };
        }
    }

    const all = await prisma.mandiNews.findMany({ orderBy, take, skip });
    return {
        items: all.map(mapDbArticle),
        scope: 'national',
        isFallback: Boolean(district || state),
    };
};

const fetchLiveGoogleNews = async ({ district, state, take }) => {
    const queries = buildLocationQueries({ district, state });
    const batches = await Promise.allSettled(
        queries.map((query) => fetchGoogleNewsRss(query)),
    );

    const merged = [];
    for (const result of batches) {
        if (result.status === 'fulfilled') merged.push(...result.value);
    }

    const tagged = tagLocation(merged, { district, state });
    return dedupeByTitle(tagged)
        .sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt))
        .slice(0, take);
};

const getNews = async ({ district, state, limit = 20, page = 1, includeGoogle = false }) => {
    const take = Number(limit);
    const skip = (Number(page) - 1) * take;
    const cacheKey = `news_feed:${district || 'all'}:${state || 'all'}:${page}:${take}:${includeGoogle}`;
    const cached = await safeRedisGet(cacheKey);
    if (cached) return cached;

    const dbResult = await fetchDbNews({ district, state, take, skip });

    let items = dbResult.items;
    let scope = dbResult.scope;
    let isFallback = dbResult.isFallback;
    let sourceMix = 'database';

    // Live Google RSS only when explicitly requested AND DB has fewer articles than needed
    if (includeGoogle && dbResult.items.length < take) {
        try {
            const googleItems = await fetchLiveGoogleNews({ district, state, take: take * 2 });
            items = dedupeByTitle([...dbResult.items, ...googleItems])
                .sort((a, b) => new Date(b.publishedAt) - new Date(a.publishedAt))
                .slice(skip, skip + take);

            if (googleItems.length > 0) {
                sourceMix = dbResult.items.length > 0 ? 'database+google' : 'google';
                if (dbResult.items.length === 0) {
                    scope = district ? 'district' : state ? 'state' : 'national';
                    isFallback = false;
                }
            }
        } catch (err) {
            logger.warn(`Google News RSS fetch failed: ${err.message}`);
        }
    }

    const payload = { items, scope, isFallback, sourceMix };
    await safeRedisSet(cacheKey, NEWS_CACHE_TTL, payload);
    return payload;
};

const syncGoogleNewsToDb = async (locations = DEFAULT_DISTRICTS) => {
    let created = 0;
    let skipped = 0;

    for (const loc of locations) {
        const query = `${loc.district} agriculture mandi farmer ${loc.state} India when:14d`;
        let items = [];
        try {
            items = await fetchGoogleNewsRss(query);
        } catch (err) {
            logger.warn(`RSS sync failed for ${loc.district}: ${err.message}`);
            continue;
        }

        const batch = items.slice(0, 8);
        if (batch.length === 0) continue;

        const titles = batch.map((item) => item.title);
        const existing = await prisma.mandiNews.findMany({
            where: {
                OR: titles.map((title) => ({ title: { equals: title, mode: 'insensitive' } })),
            },
            select: { title: true },
        });
        const existingTitles = new Set(existing.map((row) => row.title.toLowerCase().trim()));

        const toCreate = batch.filter((item) => {
            const key = item.title.toLowerCase().trim();
            if (existingTitles.has(key)) {
                skipped++;
                return false;
            }
            existingTitles.add(key);
            return true;
        });

        if (toCreate.length === 0) continue;

        const result = await prisma.mandiNews.createMany({
            data: toCreate.map((item) => ({
                title: item.title.slice(0, 500),
                content: item.content.slice(0, 4000),
                source: item.source || 'Google News',
                imageUrl: item.imageUrl,
                state: loc.state,
                district: loc.district,
                crop: item.crop,
                publishedAt: item.publishedAt,
            })),
            skipDuplicates: true,
        });
        created += result.count;
    }

    logger.info(`Google News RSS sync complete — created: ${created}, skipped: ${skipped}`);
    return { created, skipped, districts: locations.length };
};

const createManualNews = async ({ title, content, source, imageUrl, state, district, crop }) => {
    return prisma.mandiNews.create({
        data: {
            title,
            content,
            source,
            imageUrl,
            state,
            district,
            crop,
            publishedAt: new Date(),
        },
    });
};

module.exports = {
    getNews,
    syncGoogleNewsToDb,
    createManualNews,
    fetchGoogleNewsRss,
    buildGoogleNewsRssUrl,
    DEFAULT_DISTRICTS,
};
