const normalizeUserLanguage = (raw) => {
    const v = (raw || 'en').toString().toLowerCase().trim();
    if (v === 'mr' || v.includes('marathi') || v.includes('मराठी')) return 'mr';
    if (v === 'hi' || v.includes('hindi') || v.includes('हिन')) return 'hi';
    if (v === 'en' || v.includes('english')) return 'en';
    return 'en';
};

const resolveAiLanguage = (requested, userLanguage) => {
    const normalized = normalizeUserLanguage(requested || userLanguage || 'en');
    const map = {
        mr: {
            code: 'mr',
            name: 'Marathi',
            rule: 'CRITICAL: Respond ONLY in Marathi (मराठी). Use Devanagari script for all text. Do NOT use English sentences except chemical/brand names.',
        },
        hi: {
            code: 'hi',
            name: 'Hindi',
            rule: 'CRITICAL: Respond ONLY in Hindi (हिंदी). Use Devanagari script for all text. Do NOT use English sentences except chemical/brand names.',
        },
        en: {
            code: 'en',
            name: 'English',
            rule: 'CRITICAL: Respond ONLY in English. Do NOT use Hindi or Marathi unless quoting a local crop name.',
        },
    };
    return map[normalized] || map.en;
};

const languageInstruction = (requested, userLanguage) => {
    const lang = resolveAiLanguage(requested, userLanguage);
    return `${lang.rule}\nUser app language: ${lang.name}. Every field in JSON and every chat sentence must be in ${lang.name}.`;
};

module.exports = { normalizeUserLanguage, resolveAiLanguage, languageInstruction };
