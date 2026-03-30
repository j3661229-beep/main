const axios = require('axios');
const logger = require('../utils/logger');

const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID;
const ONESIGNAL_REST_KEY = process.env.ONESIGNAL_REST_KEY;

const sendNotification = async ({ users, segments, title, message, data }) => {
    if (!ONESIGNAL_APP_ID || !ONESIGNAL_REST_KEY) {
        logger.warn('OneSignal credentials missing. Skipping notification.');
        return;
    }

    try {
        const body = {
            app_id: ONESIGNAL_APP_ID,
            headings: { en: title },
            contents: { en: message },
            data: data || {},
        };

        if (users && users.length > 0) {
            body.include_external_user_ids = users;
        } else if (segments && segments.length > 0) {
            body.included_segments = segments;
        } else {
            body.included_segments = ["Subscribed Users"];
        }

        const response = await axios.post('https://onesignal.com/api/v1/notifications', body, {
            headers: {
                'Authorization': `Basic ${ONESIGNAL_REST_KEY}`,
                'Content-Type': 'application/json',
            },
        });

        logger.info(`OneSignal notification sent: ${response.data.id}`);
        return response.data;
    } catch (e) {
        logger.error(`OneSignal error: ${e.response?.data ? JSON.stringify(e.response.data) : e.message}`);
    }
};

module.exports = { sendNotification };
