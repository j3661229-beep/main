const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('🌱 Seeding AgriMart database...');

    // Create admin user
    const admin = await prisma.user.upsert({
        where: { phone: '+919999999999' },
        update: {},
        create: {
            phone: '+919999999999',
            name: 'AgriMart Admin',
            role: 'ADMIN',
            language: 'english',
            isVerified: true,
            isActive: true,
        },
    });
    console.log('✅ Admin user created:', admin.phone);

    // Create a test farmer
    const farmerUser = await prisma.user.upsert({
        where: { phone: '+919876543210' },
        update: {},
        create: {
            phone: '+919876543210',
            name: 'Ramesh Patil',
            role: 'FARMER',
            language: 'marathi',
            isVerified: true,
        },
    });
    const farmer = await prisma.farmer.upsert({
        where: { userId: farmerUser.id },
        update: {},
        create: {
            userId: farmerUser.id,
            village: 'Niphad',
            taluka: 'Niphad',
            district: 'Nashik',
            state: 'Maharashtra',
            pincode: '422303',
            latitude: 20.08,
            longitude: 74.10,
            farmSizeAcres: 4.5,
            soilType: 'Red-Black',
            waterSource: 'Borewell',
            currentCrops: ['Onion', 'Grapes'],
        },
    });
    console.log('✅ Farmer created:', farmerUser.name);

    // Create a test supplier
    const supplierUser = await prisma.user.upsert({
        where: { phone: '+918765432109' },
        update: {},
        create: {
            phone: '+918765432109',
            name: 'Suresh Agri Supplies',
            role: 'SUPPLIER',
            language: 'hindi',
            isVerified: true,
        },
    });
    const supplier = await prisma.supplier.upsert({
        where: { userId: supplierUser.id },
        update: {},
        create: {
            userId: supplierUser.id,
            businessName: 'Suresh Agri Supplies',
            gstNumber: '27AAAAA0000A1Z5',
            address: '12, Agri Market, Nashik-Pune Road',
            district: 'Nashik',
            pincode: '422001',
            latitude: 19.99,
            longitude: 73.79,
            isVerified: true,
            rating: 4.6,
            totalRatings: 128,
        },
    });
    console.log('✅ Supplier created:', supplierUser.name);

    // Create products
    const products = [
        { name: 'DAP Fertilizer', nameMarathi: 'डीएपी खत', category: 'FERTILIZER', price: 1350, unit: 'per 50kg bag', stock: 500, organic: false, brand: 'IFFCO', desc: 'Di-Ammonium Phosphate. Essential nutrients for all crops.' },
        { name: 'PM-PM Bt Cotton Seeds', nameMarathi: 'बीटी कापूस बियाणे', category: 'SEEDS', price: 750, unit: 'per 450g packet', stock: 200, organic: false, brand: 'Mahyco', desc: 'High-yield Bt Cotton hybrid for Maharashtra farmers.' },
        { name: 'Chlorpyrifos 20% EC', nameMarathi: 'क्लोरपायरीफॉस', category: 'PESTICIDE', price: 360, unit: 'per 500ml', stock: 300, organic: false, brand: 'Bayer', desc: 'Broad-spectrum insecticide for soil and foliar pests.' },
        { name: 'Organic Vermicompost', nameMarathi: 'गांडूळ खत', category: 'ORGANIC', price: 420, unit: 'per 25kg bag', stock: 1000, organic: true, brand: 'NatureFarm', desc: '100% organic vermicompost. Improves soil health.' },
        { name: 'Urea (46-0-0)', nameMarathi: 'युरिया', category: 'FERTILIZER', price: 267, unit: 'per 45kg bag', stock: 800, organic: false, brand: 'National', desc: 'High nitrogen content for vegetative growth.' },
        { name: 'Onion Seeds (Nashik Red)', nameMarathi: 'नाशिक लाल कांदा बियाणे', category: 'SEEDS', price: 890, unit: 'per 500g packet', stock: 150, organic: false, brand: 'Advanta', desc: 'Premium Nashik Red onion variety for high-yield growing.' },
    ];

    for (const p of products) {
        await prisma.product.create({
            data: {
                supplierId: supplier.id,
                name: p.name,
                nameMarathi: p.nameMarathi,
                description: p.desc,
                category: p.category,
                price: p.price,
                unit: p.unit,
                stockQuantity: p.stock,
                isOrganic: p.organic,
                brand: p.brand,
                isActive: true,
                isApproved: true,
                images: [],
            },
        });
    }
    console.log(`✅ Created ${products.length} products`);

    // Govt schemes
    const schemes = [
        { title: 'PM-KISAN Samman Nidhi', ministry: 'Ministry of Agriculture', benefits: '₹6,000 per year in 3 equal installments', eligibility: 'All small and marginal farmers with less than 2 hectares of land', docs: ['Aadhaar Card', 'Land Records (7/12 Utara)', 'Bank Passbook'], url: 'https://pmkisan.gov.in' },
        { title: 'Pradhan Mantri Fasal Bima Yojana', ministry: 'Ministry of Agriculture', benefits: 'Up to 100% crop loss compensation', eligibility: 'All farmers growing notified crops in notified areas', docs: ['Aadhaar Card', 'Land Records', 'Bank Account', 'Sowing Certificate'], url: 'https://pmfby.gov.in' },
        { title: 'Kisan Credit Card (KCC)', ministry: 'Ministry of Finance', benefits: 'Credit limit up to ₹3 lakh at 4% interest rate', eligibility: 'Individual farmers, tenant farmers, sharecroppers', docs: ['Aadhaar Card', 'Land Records', 'Identity Proof'], url: 'https://www.nabard.org/kcc' },
    ];
    for (const s of schemes) {
        await prisma.governmentScheme.create({
            data: { title: s.title, ministry: s.ministry, description: s.title, benefits: s.benefits, eligibility: s.eligibility, documents: s.docs, applyUrl: s.url },
        });
    }
    console.log(`✅ Created ${schemes.length} government schemes`);

    console.log('\n🎉 Seed complete! AgriMart database is ready.');
}

main().catch((e) => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
