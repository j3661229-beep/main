/**
 * Seed Admin User — run once to create the admin account
 * Usage: node prisma/seed-admin.js
 */
require('dotenv').config();

const { PrismaClient } = require('../src/generated/prisma');
const prisma = new PrismaClient();

async function main() {
    const adminPhone = '+919999999999';
    
    // Check if admin already exists
    const existing = await prisma.user.findUnique({ where: { phone: adminPhone } });
    
    if (existing) {
        if (existing.role === 'ADMIN') {
            console.log('✅ Admin user already exists:', existing.id);
        } else {
            // Update role to ADMIN
            const updated = await prisma.user.update({
                where: { phone: adminPhone },
                data: { role: 'ADMIN', isVerified: true, isActive: true }
            });
            console.log('✅ Updated existing user to ADMIN:', updated.id);
        }
    } else {
        // Create new admin user
        const admin = await prisma.user.create({
            data: {
                phone: adminPhone,
                name: 'AgriMart Admin',
                role: 'ADMIN',
                isVerified: true,
                isActive: true,
                language: 'english',
            }
        });
        console.log('✅ Admin user created:', admin.id);
    }

    console.log('\n📱 Admin Phone: +919999999999');
    console.log('🔑 Admin Password:', process.env.ADMIN_PASSWORD || '(not set in .env!)');
}

main()
    .catch(e => { console.error('❌ Error:', e.message); process.exit(1); })
    .finally(() => prisma.$disconnect());
