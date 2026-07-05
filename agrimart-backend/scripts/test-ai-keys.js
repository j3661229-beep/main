require('dotenv').config();
const { GoogleGenAI } = require('@google/genai');
const axios = require('axios');

const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCP_PROJECT_ID;
const LOCATION = process.env.GOOGLE_CLOUD_LOCATION || process.env.GCP_LOCATION || 'asia-south1';
const GEMINI_PRIMARY = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const GEMINI_FALLBACK = process.env.GEMINI_FALLBACK_MODEL || 'gemini-2.5-flash-lite';
const GROQ_MODELS = (process.env.GROQ_CHAT_MODELS || 'llama-3.3-70b-versatile,llama-3.1-8b-instant').split(',').map((m) => m.trim());

async function testVertex() {
  if (!PROJECT_ID) {
    console.log('VERTEX: missing GOOGLE_CLOUD_PROJECT');
    return;
  }
  console.log('VERTEX project:', PROJECT_ID, 'location:', LOCATION);
  const ai = new GoogleGenAI({ enterprise: true, project: PROJECT_ID, location: LOCATION });
  for (const model of [GEMINI_PRIMARY, GEMINI_FALLBACK]) {
    try {
      const r = await ai.models.generateContent({ model, contents: 'Reply with exactly: OK' });
      console.log('VERTEX OK', model, '->', r.text.trim().slice(0, 80));
      return;
    } catch (e) {
      console.log('VERTEX FAIL', model, '->', e.message.split('\n')[0]);
    }
  }
}

async function testGroq() {
  let key = process.env.GROQ_API_KEY || '';
  key = key.replace(/^["']|["']$/g, '');
  if (!key) {
    console.log('GROQ: missing key');
    return;
  }
  console.log('GROQ key prefix:', key.slice(0, 8), 'length:', key.length);
  for (const model of GROQ_MODELS) {
    try {
      const r = await axios.post(
        'https://api.groq.com/openai/v1/chat/completions',
        { model, messages: [{ role: 'user', content: 'Reply with exactly: OK' }], max_tokens: 10 },
        { headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' }, timeout: 30000 }
      );
      console.log('GROQ OK', model, '->', r.data.choices[0].message.content.trim());
      return;
    } catch (e) {
      const msg = e.response?.data ? JSON.stringify(e.response.data) : e.message;
      console.log('GROQ FAIL', model, '->', msg);
    }
  }
}

(async () => {
  await testVertex();
  console.log('---');
  await testGroq();
})();
