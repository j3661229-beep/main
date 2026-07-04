require('dotenv').config();
const { PrismaClient } = require('../src/generated/prisma');
const prisma = new PrismaClient();

const EMAIL = 'sarangtawde0@gmail.com';
const GOOGLE_ID = '111826891424698286342';

const daysFromNow = (n) => {
    const d = new Date();
    d.setDate(d.getDate() + n);
    return d;
};

async function main() {
    console.log('🌱 Seeding data for Sarang Tawde account...\n');

    // Find or create user (Google login account)
    let user = await prisma.user.findFirst({
        where: { OR: [{ email: EMAIL }, { googleId: GOOGLE_ID }] },
        include: { farmer: true },
    });

    if (!user) {
        user = await prisma.user.create({
            data: {
                email: EMAIL,
                googleId: GOOGLE_ID,
                name: 'Sarang Tawde',
                role: 'FARMER',
                language: 'english',
                isVerified: true,
                isActive: true,
            },
            include: { farmer: true },
        });
        console.log('✅ Created user:', user.email);
    } else {
        console.log('✅ Found user:', user.email || user.name);
    }

    // Ensure farmer profile
    const farmer = await prisma.farmer.upsert({
        where: { userId: user.id },
        update: {
            village: 'Nashik Road',
            taluka: 'Nashik',
            district: 'Nashik',
            pincode: '422101',
            farmSizeAcres: 5.0,
            soilType: 'Black Cotton',
            waterSource: 'Borewell + Drip',
            currentCrops: ['Onion', 'Tomato', 'Grapes'],
        },
        create: {
            userId: user.id,
            village: 'Nashik Road',
            taluka: 'Nashik',
            district: 'Nashik',
            state: 'Maharashtra',
            pincode: '422101',
            latitude: 19.99,
            longitude: 73.78,
            farmSizeAcres: 5.0,
            soilType: 'Black Cotton',
            waterSource: 'Borewell + Drip',
            currentCrops: ['Onion', 'Tomato', 'Grapes'],
            bankAccountNo: '123456789012',
            ifscCode: 'SBIN0001234',
        },
    });
    console.log('✅ Farmer profile updated');

    // Get reference data from existing seed
    const supplier = await prisma.supplier.findFirst({
        where: { businessName: 'Suresh Agri Supplies' },
        include: { products: { where: { isActive: true, isApproved: true }, take: 5 } },
    });
    const supplier2 = await prisma.supplier.findFirst({
        where: { businessName: 'Green Valley Agro Inputs' },
        include: { products: { where: { isActive: true, isApproved: true }, take: 3 } },
    });
    const dealer = await prisma.dealer.findFirst({ where: { businessName: 'Kisan Trading Co.' } });
    const dealer2 = await prisma.dealer.findFirst({ where: { businessName: 'Maharashtra Crop Exchange' } });

    if (!supplier || !dealer) {
        throw new Error('Run npm run seed first to create suppliers/dealers/products.');
    }

    const products = [...supplier.products, ...(supplier2?.products ?? [])];
    if (products.length === 0) throw new Error('No products found. Run npm run seed first.');

    // Cart
    const cart = await prisma.cart.upsert({
        where: { farmerId: farmer.id },
        update: {},
        create: { farmerId: farmer.id },
    });
    const cartItems = [
        { productId: products[0].id, quantity: 2 },
        { productId: products[1]?.id ?? products[0].id, quantity: 1 },
        { productId: products[2]?.id ?? products[0].id, quantity: 3 },
    ];
    for (const item of cartItems) {
        const exists = await prisma.cartItem.findFirst({
            where: { cartId: cart.id, productId: item.productId },
        });
        if (exists) {
            await prisma.cartItem.update({ where: { id: exists.id }, data: { quantity: item.quantity } });
        } else {
            await prisma.cartItem.create({ data: { cartId: cart.id, ...item } });
        }
    }
    console.log('✅ Cart with 3 items');

    // Orders (only if none exist for this farmer)
    const existingOrders = await prisma.order.count({ where: { farmerId: farmer.id } });
    if (existingOrders === 0) {
        const p0 = products[0];
        const p1 = products[3] ?? products[0];
        const total1 = p0.price * 2 + p1.price * 1;

        const order1 = await prisma.order.create({
            data: {
                farmerId: farmer.id,
                totalAmount: total1,
                status: 'DELIVERED',
                paymentStatus: 'SUCCESS',
                paymentMethod: 'cod',
                deliveryAddress: 'Sarang Tawde, Nashik Road, Nashik 422101',
                deliveryLat: 19.99,
                deliveryLng: 73.78,
                deliveredAt: daysFromNow(-10),
                notes: 'Leave at farm gate',
                items: {
                    create: [
                        { productId: p0.id, supplierId: supplier.id, quantity: 2, price: p0.price, status: 'DELIVERED' },
                        { productId: p1.id, supplierId: p1.supplierId, quantity: 1, price: p1.price, status: 'DELIVERED' },
                    ],
                },
                payment: { create: { amount: total1, status: 'SUCCESS', method: 'cod' } },
            },
            include: { items: true },
        });

        await prisma.review.create({
            data: {
                orderItemId: order1.items[0].id,
                productId: p0.id,
                farmerId: farmer.id,
                rating: 4,
                comment: 'Good quality, will order again.',
            },
        });

        const p2 = products[4] ?? products[0];
        const total2 = p2.price * 4;
        await prisma.order.create({
            data: {
                farmerId: farmer.id,
                totalAmount: total2,
                status: 'OUT_FOR_DELIVERY',
                paymentStatus: 'SUCCESS',
                paymentMethod: 'upi',
                utrNumber: 'UTR998877665544',
                deliveryAddress: 'Sarang Tawde, Nashik Road, Nashik 422101',
                items: {
                    create: [{
                        productId: p2.id,
                        supplierId: p2.supplierId,
                        quantity: 4,
                        price: p2.price,
                        status: 'OUT_FOR_DELIVERY',
                    }],
                },
                payment: { create: { amount: total2, status: 'SUCCESS', method: 'upi' } },
            },
        });

        await prisma.order.create({
            data: {
                farmerId: farmer.id,
                totalAmount: (products[5]?.price ?? 500) * 2,
                status: 'PENDING',
                paymentStatus: 'PENDING',
                paymentMethod: 'cod',
                deliveryAddress: 'Sarang Tawde, Nashik Road, Nashik 422101',
                items: {
                    create: [{
                        productId: (products[5] ?? products[0]).id,
                        supplierId: (products[5] ?? products[0]).supplierId,
                        quantity: 2,
                        price: (products[5] ?? products[0]).price,
                    }],
                },
            },
        });
        console.log('✅ 3 orders + 1 review');
    } else {
        console.log(`⏭️  Orders already exist (${existingOrders}), skipped`);
    }

    // Trade bookings
    const existingTrades = await prisma.tradeBooking.count({ where: { farmerId: farmer.id } });
    if (existingTrades === 0 && dealer && dealer2) {
        await prisma.tradeBooking.createMany({
            data: [
                { farmerId: farmer.id, dealerId: dealer.id, cropName: 'Onion', approxQuintals: 40, pricePerQuintal: 2820, slotDate: daysFromNow(4), status: 'PENDING', notes: 'Nashik Red, Grade A' },
                { farmerId: farmer.id, dealerId: dealer.id, cropName: 'Tomato', approxQuintals: 25, pricePerQuintal: 1780, slotDate: daysFromNow(1), status: 'ACCEPTED' },
                { farmerId: farmer.id, dealerId: dealer2.id, cropName: 'Grapes', approxQuintals: 15, pricePerQuintal: 6150, slotDate: daysFromNow(-3), status: 'COMPLETED', notes: 'Thompson seedless' },
            ],
        });
        console.log('✅ 3 trade bookings');
    } else {
        console.log(`⏭️  Trade bookings already exist (${existingTrades}), skipped`);
    }

    // Price alerts
    const alerts = [
        { cropName: 'Onion', targetPrice: 2900 },
        { cropName: 'Tomato', targetPrice: 1900 },
        { cropName: 'Grapes', targetPrice: 6300 },
    ];
    for (const a of alerts) {
        const exists = await prisma.priceAlert.findFirst({
            where: { farmerId: farmer.id, cropName: a.cropName },
        });
        if (!exists) {
            await prisma.priceAlert.create({ data: { farmerId: farmer.id, ...a } });
        }
    }
    console.log('✅ 3 price alerts');

    // Soil report
    const soilCount = await prisma.soilReport.count({ where: { farmerId: farmer.id } });
    if (soilCount === 0) {
        await prisma.soilReport.create({
            data: {
                farmerId: farmer.id,
                imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?q=80&w=600',
                soilType: 'Black Cotton',
                phLevel: 7.1,
                nitrogenLevel: 'Low',
                phosphorusLevel: 'Medium',
                potassiumLevel: 'Medium',
                organicMatter: '1.8%',
                recommendedCrops: ['Onion', 'Tomato', 'Soybean'],
                treatmentAdvice: 'Apply urea 45kg/acre split dose. Add vermicompost before transplanting.',
                confidence: 0.88,
            },
        });
        console.log('✅ 1 soil report');
    }

    // Notifications
    const notifs = [
        { title: 'Welcome to AgriMart', body: 'Hi Sarang! Your farmer profile is set up. Browse products and mandi rates.', type: 'WELCOME', isRead: true },
        { title: 'Order out for delivery', body: 'Your UPI order is on the way. Expected today by 6 PM.', type: 'ORDER', isRead: false },
        { title: 'Onion rate update', body: 'Nashik APMC onion rate: ₹2,820/quintal (+2% today).', type: 'PRICE_ALERT', isRead: false },
        { title: 'Trade booking accepted', body: 'Kisan Trading Co. accepted your tomato booking for tomorrow.', type: 'TRADE', isRead: false },
        { title: 'PM-KISAN installment', body: 'Your PM-KISAN ₹2,000 installment may be credited this week.', type: 'SCHEME', isRead: false },
    ];
    let added = 0;
    for (const n of notifs) {
        const exists = await prisma.notification.findFirst({ where: { userId: user.id, title: n.title } });
        if (!exists) {
            await prisma.notification.create({ data: { userId: user.id, ...n } });
            added++;
        }
    }
    console.log(`✅ ${added} notifications`);

    console.log('\n🎉 Sarang Tawde account data ready!');
    console.log(`   Email: ${EMAIL}`);
    console.log('   Login: Google Sign-In');
}

main()
    .catch((e) => { console.error(e); process.exit(1); })
    .finally(() => prisma.$disconnect());
