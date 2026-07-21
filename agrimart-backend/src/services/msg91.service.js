const axios = require('axios');
const logger = require('../utils/logger');

const MSG91_OTP_URL = 'https://control.msg91.com/api/v5/otp';

const isConfigured = () =>
    Boolean(process.env.MSG91_AUTH_KEY?.trim() && process.env.MSG91_OTP_TEMPLATE_ID?.trim());

/** E.164 (+919876543210) → MSG91 format (919876543210) */
const toMsg91Mobile = (phone) => phone.replace(/\D/g, '');

/**
 * Send OTP SMS via MSG91 OTP widget API.
 * Template must contain ##OTP## placeholder (MSG91 dashboard → OTP → Templates).
 */
const sendOtpSms = async (phone, otp) => {
    const authkey = process.env.MSG91_AUTH_KEY?.trim();
    const templateId = process.env.MSG91_OTP_TEMPLATE_ID?.trim();
    if (!authkey || !templateId) {
        throw Object.assign(new Error('MSG91 is not configured'), { statusCode: 503 });
    }

    const mobile = toMsg91Mobile(phone);
    if (mobile.length < 12) {
        throw Object.assign(new Error('Invalid phone number for SMS'), { statusCode: 400 });
    }

    const payload = {
        template_id: templateId,
        mobile,
        otp: String(otp),
        otp_length: '6',
        otp_expiry: '10',
    };

    logger.info(`MSG91 OTP request for ${mobile.slice(0, 4)}****${mobile.slice(-2)}`);

    const { data } = await axios.post(MSG91_OTP_URL, payload, {
        headers: {
            authkey,
            'Content-Type': 'application/json',
            accept: 'application/json',
        },
        timeout: 15000,
        validateStatus: () => true,
    });

    if (data?.type === 'error' || (data?.message && !data?.request_id && data?.type !== 'success')) {
        const msg = data?.message || 'MSG91 OTP send failed';
        logger.error(`MSG91 OTP error: ${msg}`, { data });
        throw Object.assign(new Error(msg), { statusCode: 502 });
    }

    logger.info(`MSG91 OTP sent (request_id: ${data?.request_id || 'ok'})`);
    return data;
};

module.exports = { isConfigured, sendOtpSms, toMsg91Mobile };
