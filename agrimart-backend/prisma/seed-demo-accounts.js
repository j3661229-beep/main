require('dotenv').config();
const bcrypt = require('bcryptjs');
const { PrismaClient } = require('../src/generated/prisma');

const prisma = new PrismaClient();

const DEMO_ACCOUNTS = [
    {
        role: 'SUPPLIER',
        email: 'supplier@agrimart.in',
        password: 'Supplier@123',
        phone: '+919988776601',
        name: 'Rajesh Agro Supplies',
        language: 'hindi',
        profile: {
            businessName: 'Rajesh Agro Supplies',
            gstNumber: '27AAAAA1234A1Z5',
            address: 'Shop 12, Agri Market, Nashik-Pune Road',
            district: 'Nashik',
            pincode: '422001',
            latitude: 19.99,
            longitude: 73.79,
            rating: 4.7,
            totalRatings: 56,
        },
    },
    {
        role: 'DEALER',
        email: 'dealer@agrimart.in',
        password: 'Dealer@123',
        phone: '+919988776602',
        name: 'Nashik Mandi Traders',
        language: 'marathi',
        profile: {
            businessName: 'Nashik Mandi Traders',
            address: 'Lasalgaon APMC Market, Nashik',
            district: 'Nashik',
            pincode: '422306',
            latitude: 20.14,
            longitude: 74.22,
            rating: 4.8,
            totalRatings: 120,
        },
    },
];

async function upsertDemoAccount(account) {
    const passwordHash = bcrypt.hashSync(account.password, 10);

    const user = await prisma.user.upsert({
        where: { email: account.email },
        update: {
            name: account.name,
            phone: account.phone,
            role: account.role,
            language: account.language,
            passwordHash,
            isVerified: true,
            isActive: true,
        },
        create: {
            email: account.email,
            phone: account.phone,
            name: account.name,
            role: account.role,
            language: account.language,
            passwordHash,
            isVerified: true,
            isActive: true,
        },
    });

    if (account.role === 'SUPPLIER') {
        await prisma.supplier.upsert({
            where: { userId: user.id },
            update: {
                ...account.profile,
                isVerified: true,
                docStatus: 'APPROVED',
                verifiedAt: new Date(),
            },
            create: {
                userId: user.id,
                ...account.profile,
                isVerified: true,
                docStatus: 'APPROVED',
                verifiedAt: new Date(),
            },
        });
    } else if (account.role === 'DEALER') {
        await prisma.dealer.upsert({
            where: { userId: user.id },
            update: {
                ...account.profile,
                isVerified: true,
                docStatus: 'APPROVED',
                verifiedAt: new Date(),
            },
            create: {
                userId: user.id,
                ...account.profile,
                isVerified: true,
                docStatus: 'APPROVED',
                verifiedAt: new Date(),
            },
        });
    }

    return user;
}

async function main() {
    console.log('🌱 Seeding demo supplier & dealer accounts...\n');

    for (const account of DEMO_ACCOUNTS) {
        await upsertDemoAccount(account);
        console.log(`✅ ${account.role}: ${account.email}`);
    }

    console.log('\n── Login credentials (Supplier / Dealer app) ──');
    for (const account of DEMO_ACCOUNTS) {
        console.log(`${account.role}`);
        console.log(`  Email:    ${account.email}`);
        console.log(`  Password: ${account.password}`);
        console.log(`  Phone:    ${account.phone}`);
        console.log('');
    }
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(() => prisma.$disconnect());
