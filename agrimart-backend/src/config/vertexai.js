const { GoogleGenAI } = require('@google/genai');
const logger = require('../utils/logger');

const PROJECT_ID =
    process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.GCP_PROJECT_ID ||
    process.env.GCLOUD_PROJECT;

const LOCATION = process.env.GOOGLE_CLOUD_LOCATION || process.env.GCP_LOCATION || 'asia-south1';

let client = null;

const isVertexConfigured = () => Boolean(PROJECT_ID);

const getVertexClient = () => {
    if (!isVertexConfigured()) return null;
    if (!client) {
        client = new GoogleGenAI({
            enterprise: true,
            project: PROJECT_ID,
            location: LOCATION,
        });
        logger.info(`Vertex AI client initialized (project=${PROJECT_ID}, location=${LOCATION})`);
    }
    return client;
};

if (!isVertexConfigured()) {
    logger.warn(
        'GOOGLE_CLOUD_PROJECT is not set — Vertex AI features will fail. ' +
        'Set GOOGLE_CLOUD_PROJECT and run: gcloud auth application-default login'
    );
}

module.exports = { getVertexClient, isVertexConfigured, PROJECT_ID, LOCATION };
