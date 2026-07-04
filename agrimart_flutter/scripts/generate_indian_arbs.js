/**
 * Auto-translate app_en.arb into all major Indian languages.
 * Run: node scripts/generate_indian_arbs.js
 */
const fs = require('fs');
const path = require('path');

const l10nDir = path.join(__dirname, '../lib/l10n');
const en = JSON.parse(fs.readFileSync(path.join(l10nDir, 'app_en.arb'), 'utf8'));

const TARGETS = {
  bn: 'bn', te: 'te', ta: 'ta', gu: 'gu', kn: 'kn',
  ml: 'ml', pa: 'pa', or: 'or', as: 'as', ur: 'ur',
};

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function translateText(text, targetLang) {
  if (!text || !text.trim()) return text;
  // Keep placeholders intact
  const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=${targetLang}&dt=t&q=${encodeURIComponent(text)}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Translate failed ${res.status}`);
  const data = await res.json();
  return data[0].map((part) => part[0]).join('');
}

async function buildLang(langCode, googleCode) {
  const out = {};
  const keys = Object.keys(en).filter((k) => !k.startsWith('@'));
  console.log(`Translating ${langCode} (${keys.length} keys)...`);

  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    const value = en[key];
    if (typeof value !== 'string') continue;
    try {
      out[key] = await translateText(value, googleCode);
    } catch (err) {
      console.warn(`  skip ${key}: ${err.message}`);
      out[key] = value;
    }
    if (i % 5 === 0) await sleep(120);
  }

  // Preserve metadata keys from template
  for (const key of Object.keys(en)) {
    if (key.startsWith('@')) out[key] = en[key];
  }

  fs.writeFileSync(path.join(l10nDir, `app_${langCode}.arb`), JSON.stringify(out, null, 2) + '\n');
  console.log(`✅ app_${langCode}.arb`);
}

(async () => {
  for (const [lang, googleCode] of Object.entries(TARGETS)) {
    await buildLang(lang, googleCode);
  }
  console.log('\nDone! Run: flutter gen-l10n');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
