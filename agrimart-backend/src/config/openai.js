const OpenAI = require('openai');

let openai;

if (process.env.OPENAI_API_KEY) {
    openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
} else {
    // Mock for development
    openai = {
        chat: {
            completions: {
                create: async ({ messages }) => ({
                    choices: [{
                        message: {
                            content: JSON.stringify({
                                soilType: 'Red-Black Cotton Soil',
                                phLevel: 7.4,
                                nitrogenLevel: 'low',
                                phosphorusLevel: 'medium',
                                potassiumLevel: 'high',
                                organicMatter: 'medium',
                                recommendedCrops: ['Onion', 'Soybean', 'Cotton'],
                                treatmentAdvice: 'Apply Urea 45kg/acre for nitrogen deficiency',
                                confidence: 0.94,
                            }),
                        },
                    }],
                }),
            },
        },
    };
}

module.exports = openai;
