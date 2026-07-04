const prisma = require('../config/database');
const mandiService = require('./mandi.service');
const { sendNotification } = require('./onesignal.service');
const logger = require('../utils/logger');

const normalizeCrop = (name = '') => name.toLowerCase().trim();

const checkPriceAlerts = async () => {
    const alerts = await prisma.priceAlert.findMany({
        where: { isActive: true },
        include: { farmer: { include: { user: true } } },
    });
    if (!alerts.length) return { checked: 0, triggered: 0 };

    const districts = [...new Set(alerts.map((a) => a.farmer?.district).filter(Boolean))];
    const priceByCrop = {};

    for (const district of districts.length ? districts : ['Nashik']) {
        try {
            const mandi = await mandiService.getPrices({ district, page: 1, limit: 50 });
            for (const row of mandi.prices || []) {
                const key = normalizeCrop(row.crop);
                if (!priceByCrop[key] || row.price > priceByCrop[key]) {
                    priceByCrop[key] = row.price;
                }
            }
        } catch (err) {
            logger.warn(`Price alert mandi fetch failed for ${district}: ${err.message}`);
        }
    }

    let triggered = 0;
    for (const alert of alerts) {
        const current = priceByCrop[normalizeCrop(alert.cropName)];
        if (current == null || current < alert.targetPrice) continue;

        const userId = alert.farmer?.userId;
        if (userId) {
            sendNotification({
                users: [userId],
                title: `🎯 ${alert.cropName} price alert`,
                message: `Mandi price is ₹${Math.round(current)}/qtl — your target was ₹${Math.round(alert.targetPrice)}/qtl`,
                data: { type: 'PRICE_ALERT', crop: alert.cropName, price: current },
            });
        }
        await prisma.priceAlert.update({ where: { id: alert.id }, data: { isActive: false } });
        triggered++;
    }

    logger.info(`Price alerts checked: ${alerts.length}, triggered: ${triggered}`);
    return { checked: alerts.length, triggered };
};

module.exports = { checkPriceAlerts };
