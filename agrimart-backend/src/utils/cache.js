const NodeCache = require('node-cache');
const logger = require('./logger');

// TTL: 1 hour by default
const myCache = new NodeCache({ stdTTL: 3600, checkperiod: 600 });

const get = async (key) => {
    try {
        return myCache.get(key);
    } catch (e) {
        logger.error(`Cache Get Error: ${e.message}`);
        return null;
    }
};

const set = async (key, value, ttl = 3600) => {
    try {
        return myCache.set(key, value, ttl);
    } catch (e) {
        logger.error(`Cache Set Error: ${e.message}`);
    }
};

const del = async (key) => {
    try {
        return myCache.del(key);
    } catch (e) {
        logger.error(`Cache Del Error: ${e.message}`);
    }
};

module.exports = { get, set, del };
