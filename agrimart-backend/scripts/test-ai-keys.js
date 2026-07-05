require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');
const axios = require('axios');

const GEMINI_PRIMARY = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const GEMINI_FALLBACK = process.env.GEMINI_FALLBACK_MODEL || 'gemini-2.5-flash-lite';
const GROQ_MODELS = (process.env.GROQ_CHAT_MODELS || 'llama-3.3-70b-versatile,llama-3.1-8b-instant').split(',').map((m) => m.trim());

async function testGemini() {
  const key = process.env.GEMINI_API_KEY;
  if (!key) {
    console.log('GEMINI: missing key');
    return;
  }
  console.log('GEMINI key prefix:', key.slice(0, 8), 'length:', key.length);
  const genAI = new GoogleGenerativeAI(key);
  for (const model of [GEMINI_PRIMARY, GEMINI_FALLBACK]) {
    try {
      const m = genAI.getGenerativeModel({ model });
      const r = await m.generateContent('Reply with exactly: OK');
      console.log('GEMINI OK', model, '->', r.response.text().trim().slice(0, 80));
      return;
    } catch (e) {
      console.log('GEMINI FAIL', model, '->', e.message.split('\n')[0]);
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
  await testGemini();
  console.log('---');
  await testGroq();
})();
