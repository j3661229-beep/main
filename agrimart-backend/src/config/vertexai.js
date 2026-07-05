const { GoogleGenAI } = require('@google/genai');
const { GoogleAuth } = require('google-auth-library');
const logger = require('../utils/logger');

let projectId =
    process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.GCP_PROJECT_ID ||
    process.env.GCLOUD_PROJECT ||
    null;

// Cloud Run service URL uses europe-west1 — match Vertex region
const LOCATION =
    process.env.GOOGLE_CLOUD_LOCATION ||
    process.env.GCP_LOCATION ||
    (process.env.K_SERVICE ? 'europe-west1' : 'asia-south1');

let client = null;
let initPromise = null;

const resolveProjectId = async () => {
    if (projectId) return projectId;
    try {
        const auth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/cloud-platform'] });
        projectId = await auth.getProjectId();
        if (projectId) {
            logger.info(`Vertex AI project auto-detected via ADC: ${projectId}`);
        }
    } catch (e) {
        logger.warn(`Vertex AI project auto-detect failed: ${e.message}`);
    }
    return projectId;
};

const getVertexClient = async () => {
    if (client) return client;
    if (!initPromise) {
        initPromise = (async () => {
            const pid = await resolveProjectId();
            if (!pid) {
                logger.error(
                    'Vertex AI unavailable: set GOOGLE_CLOUD_PROJECT on Cloud Run, ' +
                    'or run gcloud auth application-default login locally.'
                );
                return null;
            }
            client = new GoogleGenAI({ enterprise: true, project: pid, location: LOCATION });
            logger.info(`Vertex AI client ready (project=${pid}, location=${LOCATION})`);
            return client;
        })();
    }
    return initPromise;
};

const isVertexConfigured = () =>
    Boolean(projectId || process.env.GOOGLE_CLOUD_PROJECT || process.env.K_SERVICE);

module.exports = { getVertexClient, isVertexConfigured, get PROJECT_ID() { return projectId; }, LOCATION };
