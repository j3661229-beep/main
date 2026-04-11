const { PrismaClient } = require('../generated/prisma');

const prisma = new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
    // Connection pool tuning for production
    // datasources URL params: ?connection_limit=10&pool_timeout=20
});

// Graceful shutdown — release DB pool
process.on('beforeExit', async () => {
    await prisma.$disconnect();
});

module.exports = prisma;
