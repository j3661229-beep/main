const sharp = require('sharp');
const logger = require('./logger');

const SKIP_BELOW_BYTES = 380 * 1024;
const MAX_SIDE = 1280;
const QUALITY = 82;

/**
 * Resize & compress AI upload images (WebP preferred, JPEG fallback).
 * Returns { buffer, mime, ext } safe for Gemini/base64 pipelines.
 */
const optimizeAiImage = async (buffer, { maxSide = MAX_SIDE, quality = QUALITY } = {}) => {
    if (!buffer?.length) {
        return { buffer: buffer || Buffer.alloc(0), mime: 'image/jpeg', ext: 'jpg' };
    }
    if (buffer.length <= SKIP_BELOW_BYTES) {
        return { buffer, mime: 'image/jpeg', ext: 'jpg' };
    }

    try {
        const base = sharp(buffer, { failOn: 'none' }).rotate();
        const meta = await base.metadata();
        const resizeOpts = {
            width: (meta.width || 0) >= (meta.height || 0) ? maxSide : undefined,
            height: (meta.height || 0) > (meta.width || 0) ? maxSide : undefined,
            fit: 'inside',
            withoutEnlargement: true,
        };

        let output = await sharp(buffer).rotate().resize(resizeOpts).webp({ quality }).toBuffer();
        let mime = 'image/webp';
        let ext = 'webp';

        if (output.length >= buffer.length) {
            output = await sharp(buffer).rotate().resize(resizeOpts).jpeg({ quality, mozjpeg: true }).toBuffer();
            mime = 'image/jpeg';
            ext = 'jpg';
        }

        if (output.length < buffer.length) {
            logger.info(`AI image optimized: ${Math.round(buffer.length / 1024)}KB → ${Math.round(output.length / 1024)}KB (${ext})`);
            return { buffer: output, mime, ext };
        }
        return { buffer, mime: 'image/jpeg', ext: 'jpg' };
    } catch (err) {
        logger.warn(`AI image optimize skipped: ${err.message}`);
        return { buffer, mime: 'image/jpeg', ext: 'jpg' };
    }
};

module.exports = { optimizeAiImage };
