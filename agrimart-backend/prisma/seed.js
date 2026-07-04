require('dotenv').config();
const { PrismaClient } = require('../src/generated/prisma');
const prisma = new PrismaClient();

const daysFromNow = (n) => {
    const d = new Date();
    d.setDate(d.getDate() + n);
    return d;
};

async function upsertUser({ phone, email, name, role, language, isVerified = true }) {
    const where = phone ? { phone } : { email };
    return prisma.user.upsert({
        where,
        update: { name, isVerified },
        create: { phone, email, name, role, language, isVerified, isActive: true },
    });
}

async function ensureProduct(supplierId, p) {
    const existing = await prisma.product.findFirst({
        where: { supplierId, name: p.name },
    });
    if (existing) return existing;
    return prisma.product.create({
        data: {
            supplierId,
            name: p.name,
            nameMarathi: p.nameMarathi,
            nameHindi: p.nameHindi,
            description: p.desc,
            category: p.category,
            price: p.price,
            unit: p.unit,
            stockQuantity: p.stock,
            isOrganic: p.organic ?? false,
            brand: p.brand,
            isActive: true,
            isApproved: true,
            images: p.images ?? [],
        },
    });
}

async function ensureScheme(s) {
    const existing = await prisma.governmentScheme.findFirst({ where: { title: s.title } });
    if (existing) return existing;
    return prisma.governmentScheme.create({
        data: {
            title: s.title,
            titleMarathi: s.titleMarathi,
            ministry: s.ministry,
            description: s.description ?? s.title,
            benefits: s.benefits,
            eligibility: s.eligibility,
            documents: s.docs,
            applyUrl: s.url,
            isActive: true,
        },
    });
}

async function ensureNews(n) {
    const existing = await prisma.mandiNews.findFirst({ where: { title: n.title } });
    if (existing) return existing;
    return prisma.mandiNews.create({
        data: {
            title: n.title,
            content: n.content,
            source: n.source,
            district: n.district,
            state: n.state,
            crop: n.crop,
            imageUrl: n.imageUrl,
            publishedAt: n.publishedAt ?? new Date(),
        },
    });
}

async function main() {
    console.log('🌱 Seeding AgriMart database...\n');

    // ── Admin ───────────────────────────────────────────────
    await upsertUser({
        phone: '+919999999999',
        name: 'AgriMart Admin',
        role: 'ADMIN',
        language: 'english',
    });
    console.log('✅ Admin');

    // ── Farmers ─────────────────────────────────────────────
    const farmerDefs = [
        {
            phone: '+919876543210', name: 'Ramesh Patil', language: 'marathi',
            village: 'Niphad', taluka: 'Niphad', district: 'Nashik', pincode: '422303',
            lat: 20.08, lng: 74.10, acres: 4.5, soil: 'Red-Black', water: 'Borewell',
            crops: ['Onion', 'Grapes'],
        },
        {
            phone: '+919123456789', name: 'Sunil Kadam', language: 'marathi',
            village: 'Sinnar', taluka: 'Sinnar', district: 'Nashik', pincode: '422103',
            lat: 19.85, lng: 73.99, acres: 6.0, soil: 'Black', water: 'Canal',
            crops: ['Soybean', 'Wheat'],
        },
        {
            phone: '+919234567890', name: 'Anita Deshmukh', language: 'marathi',
            village: 'Baramati', taluka: 'Baramati', district: 'Pune', pincode: '413102',
            lat: 18.15, lng: 74.58, acres: 3.2, soil: 'Alluvial', water: 'Drip',
            crops: ['Tomato', 'Chilli'],
        },
    ];

    const farmers = [];
    for (const f of farmerDefs) {
        const user = await upsertUser({ phone: f.phone, name: f.name, role: 'FARMER', language: f.language });
        const farmer = await prisma.farmer.upsert({
            where: { userId: user.id },
            update: {},
            create: {
                userId: user.id,
                village: f.village, taluka: f.taluka, district: f.district,
                pincode: f.pincode, latitude: f.lat, longitude: f.lng,
                farmSizeAcres: f.acres, soilType: f.soil, waterSource: f.water,
                currentCrops: f.crops,
            },
        });
        farmers.push({ user, farmer });
    }
    console.log(`✅ ${farmers.length} farmers`);

    // ── Suppliers ───────────────────────────────────────────
    const supplierDefs = [
        {
            phone: '+918765432109', name: 'Suresh Agri Supplies', businessName: 'Suresh Agri Supplies',
            gst: '27AAAAA0000A1Z5', address: '12, Agri Market, Nashik-Pune Road',
            district: 'Nashik', pincode: '422001', lat: 19.99, lng: 73.79,
            rating: 4.6, totalRatings: 128,
        },
        {
            phone: '+918888777666', name: 'Green Valley Inputs', businessName: 'Green Valley Agro Inputs',
            gst: '27CCCCC0000C3Z8', address: 'Shop 5, Pune-Satara Road, Baramati',
            district: 'Pune', pincode: '413102', lat: 18.15, lng: 74.58,
            rating: 4.3, totalRatings: 89,
        },
    ];

    const suppliers = [];
    for (const s of supplierDefs) {
        const user = await upsertUser({ phone: s.phone, name: s.name, role: 'SUPPLIER', language: 'hindi' });
        const supplier = await prisma.supplier.upsert({
            where: { userId: user.id },
            update: { isVerified: true, docStatus: 'APPROVED' },
            create: {
                userId: user.id,
                businessName: s.businessName,
                gstNumber: s.gst,
                address: s.address,
                district: s.district,
                pincode: s.pincode,
                latitude: s.lat,
                longitude: s.lng,
                isVerified: true,
                docStatus: 'APPROVED',
                rating: s.rating,
                totalRatings: s.totalRatings,
            },
        });
        suppliers.push({ user, supplier });
    }
    console.log(`✅ ${suppliers.length} suppliers`);

    // ── Dealers ─────────────────────────────────────────────
    const dealerDefs = [
        {
            phone: '+917654321098', name: 'Kisan Trading Co.', businessName: 'Kisan Trading Co.',
            address: 'Lasalgaon APMC Market, Nashik', district: 'Nashik', pincode: '422306',
            lat: 20.14, lng: 74.22, rating: 4.8, totalRatings: 342,
        },
        {
            phone: '+917777888999', name: 'Maharashtra Crop Exchange', businessName: 'Maharashtra Crop Exchange',
            address: 'Market Yard, Pune', district: 'Pune', pincode: '411037',
            lat: 18.52, lng: 73.85, rating: 4.5, totalRatings: 210,
        },
    ];

    const dealers = [];
    for (const d of dealerDefs) {
        const user = await upsertUser({ phone: d.phone, name: d.name, role: 'DEALER', language: 'english' });
        const dealer = await prisma.dealer.upsert({
            where: { userId: user.id },
            update: { isVerified: true, docStatus: 'APPROVED' },
            create: {
                userId: user.id,
                businessName: d.businessName,
                address: d.address,
                district: d.district,
                pincode: d.pincode,
                latitude: d.lat,
                longitude: d.lng,
                isVerified: true,
                docStatus: 'APPROVED',
                rating: d.rating,
                totalRatings: d.totalRatings,
            },
        });
        dealers.push({ user, dealer });
    }
    console.log(`✅ ${dealers.length} dealers`);

    // ── Products ────────────────────────────────────────────
    const productCatalog = [
        // Suresh Agri Supplies
        { supplierIdx: 0, name: 'DAP Fertilizer', nameMarathi: 'डीएपी खत', category: 'FERTILIZER', price: 1350, unit: 'per 50kg bag', stock: 500, brand: 'IFFCO', desc: 'Di-Ammonium Phosphate for all crops.' },
        { supplierIdx: 0, name: 'PM-PM Bt Cotton Seeds', nameMarathi: 'बीटी कापूस बियाणे', category: 'SEEDS', price: 750, unit: 'per 450g packet', stock: 200, brand: 'Mahyco', desc: 'High-yield Bt Cotton hybrid.' },
        { supplierIdx: 0, name: 'Chlorpyrifos 20% EC', nameMarathi: 'क्लोरपायरीफॉस', category: 'PESTICIDE', price: 360, unit: 'per 500ml', stock: 300, brand: 'Bayer', desc: 'Broad-spectrum insecticide.' },
        { supplierIdx: 0, name: 'Organic Vermicompost', nameMarathi: 'गांडूळ खत', category: 'ORGANIC', price: 420, unit: 'per 25kg bag', stock: 1000, organic: true, brand: 'NatureFarm', desc: '100% organic vermicompost.' },
        { supplierIdx: 0, name: 'Urea (46-0-0)', nameMarathi: 'युरिया', category: 'FERTILIZER', price: 267, unit: 'per 45kg bag', stock: 800, brand: 'National', desc: 'High nitrogen for vegetative growth.' },
        { supplierIdx: 0, name: 'Onion Seeds (Nashik Red)', nameMarathi: 'नाशिक लाल कांदा बियाणे', category: 'SEEDS', price: 890, unit: 'per 500g packet', stock: 150, brand: 'Advanta', desc: 'Premium Nashik Red onion variety.' },
        { supplierIdx: 0, name: 'Sprayer Pump 16L', nameMarathi: 'स्प्रेयर पंप', category: 'EQUIPMENT', price: 1850, unit: 'per unit', stock: 45, brand: 'Neptune', desc: 'Manual knapsack sprayer for pesticides.' },
        { supplierIdx: 0, name: 'MOP Potash', nameMarathi: 'पोटॅश', category: 'FERTILIZER', price: 980, unit: 'per 50kg bag', stock: 350, brand: 'IFFCO', desc: 'Muriate of Potash for fruit crops.' },
        // Green Valley Inputs
        { supplierIdx: 1, name: 'Hybrid Tomato Seeds', nameMarathi: 'टोमॅटो बियाणे', category: 'SEEDS', price: 620, unit: 'per 10g packet', stock: 180, brand: 'Seminis', desc: 'Disease-resistant hybrid tomato.' },
        { supplierIdx: 1, name: 'Neem Oil 1500ppm', nameMarathi: 'नीम तेल', category: 'ORGANIC', price: 280, unit: 'per 500ml', stock: 400, organic: true, brand: 'EcoFarm', desc: 'Organic pest control neem oil.' },
        { supplierIdx: 1, name: 'Glyphosate 41% SL', nameMarathi: 'ग्लिफोसेट', category: 'PESTICIDE', price: 410, unit: 'per 1L', stock: 220, brand: 'UPL', desc: 'Non-selective herbicide for weed control.' },
        { supplierIdx: 1, name: 'Drip Irrigation Kit', nameMarathi: 'ठिबक सिंचन किट', category: 'EQUIPMENT', price: 4500, unit: 'per acre kit', stock: 30, brand: 'Jain', desc: 'Complete drip kit for 1 acre.' },
        { supplierIdx: 1, name: 'Zinc Sulphate', nameMarathi: 'झिंक सल्फेट', category: 'FERTILIZER', price: 145, unit: 'per 500g', stock: 600, brand: 'Coromandel', desc: 'Micronutrient for zinc deficiency.' },
        { supplierIdx: 1, name: 'Soybean Seeds (JS-335)', nameMarathi: 'सोयाबीन बियाणे', category: 'SEEDS', price: 540, unit: 'per 40kg bag', stock: 90, brand: 'Nuziveedu', desc: 'High-yield soybean variety for rabi.' },
    ];

    const products = [];
    for (const p of productCatalog) {
        const { supplierIdx, ...data } = p;
        products.push(await ensureProduct(suppliers[supplierIdx].supplier.id, data));
    }
    console.log(`✅ ${products.length} products`);

    // ── Govt Schemes ────────────────────────────────────────
    const schemes = [
        { title: 'PM-KISAN Samman Nidhi', titleMarathi: 'पीएम-किसान', ministry: 'Ministry of Agriculture', benefits: '₹6,000 per year in 3 equal installments', eligibility: 'Small and marginal farmers with less than 2 hectares', docs: ['Aadhaar Card', 'Land Records (7/12 Utara)', 'Bank Passbook'], url: 'https://pmkisan.gov.in' },
        { title: 'Pradhan Mantri Fasal Bima Yojana', titleMarathi: 'पीएम फसल बीमा', ministry: 'Ministry of Agriculture', benefits: 'Up to 100% crop loss compensation', eligibility: 'Farmers growing notified crops in notified areas', docs: ['Aadhaar Card', 'Land Records', 'Bank Account'], url: 'https://pmfby.gov.in' },
        { title: 'Kisan Credit Card (KCC)', ministry: 'Ministry of Finance', benefits: 'Credit limit up to ₹3 lakh at 4% interest', eligibility: 'Individual farmers, tenant farmers, sharecroppers', docs: ['Aadhaar Card', 'Land Records', 'Identity Proof'], url: 'https://www.nabard.org/kcc' },
        { title: 'Soil Health Card Scheme', titleMarathi: 'माती आरोग्य कार्ड', ministry: 'Ministry of Agriculture', benefits: 'Free soil testing and crop-specific fertilizer recommendations', eligibility: 'All farmers', docs: ['Aadhaar Card'], url: 'https://soilhealth.dac.gov.in' },
        { title: 'PM FME – Formalisation of Micro Food Enterprises', ministry: 'Ministry of Food Processing', benefits: 'Seed capital up to ₹40 lakh for food processing units', eligibility: 'Existing micro food enterprises and SHGs', docs: ['Aadhaar', 'Business Registration', 'Bank Details'], url: 'https://mofpi.gov.in' },
    ];
    for (const s of schemes) await ensureScheme(s);
    console.log(`✅ ${schemes.length} government schemes`);

    // ── Mandi News ──────────────────────────────────────────
    const newsItems = [
        { title: 'Onion export ban lifted by Central Govt', content: 'The government has removed the ban on onion exports, leading to a surge in prices at Lasalgaon APMC today. Farmers are advised to hold stock for better rates.', source: 'AgriNews India', district: 'Nashik', state: 'Maharashtra', crop: 'Onion', imageUrl: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?q=80&w=600&auto=format&fit=crop' },
        { title: 'Heavy unseasonal rain damages grape harvest', content: 'Grape farmers in Niphad and Dindori suffer losses as unseasonal rains with hail hit the region. Crop insurance claims are being processed.', source: 'Local Reports', district: 'Nashik', state: 'Maharashtra', crop: 'Grapes', imageUrl: 'https://images.unsplash.com/photo-1596489375730-804910cf972d?q=80&w=600&auto=format&fit=crop' },
        { title: 'New MSP announced for Wheat', content: 'Cabinet approved an increase in MSP for Wheat for rabi season by ₹150 per quintal. Procurement will begin from April.', source: 'Govt Portal', state: 'Maharashtra', crop: 'Wheat', imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?q=80&w=600&auto=format&fit=crop' },
        { title: 'Soybean prices rise at Pune APMC', content: 'Soybean traded at ₹4,850/quintal at Pune market yard, up 3% from last week on strong export demand.', source: 'Commodity Live', district: 'Pune', state: 'Maharashtra', crop: 'Soybean', imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?q=80&w=600&auto=format&fit=crop' },
        { title: 'Tomato farmers get drip subsidy in Baramati', content: 'State agriculture dept disbursed ₹2 crore drip irrigation subsidy to 450 tomato farmers in Baramati taluka.', source: 'Krishi Jagran', district: 'Pune', state: 'Maharashtra', crop: 'Tomato', imageUrl: 'https://images.unsplash.com/photo-1546470427-e26264be0f18?q=80&w=600&auto=format&fit=crop' },
        { title: 'Cotton arrivals pick up in Maharashtra', content: 'Cotton arrivals at ginning mills across Vidarbha increased 20% week-on-week as harvesting peaks.', source: 'Cotton Corp', state: 'Maharashtra', crop: 'Cotton', imageUrl: 'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?q=80&w=600&auto=format&fit=crop' },
        { title: 'PM-KISAN 18th installment credited', content: 'Over 9 crore farmers received the 18th PM-KISAN installment of ₹2,000 directly into bank accounts.', source: 'PIB India', crop: 'All', imageUrl: 'https://images.unsplash.com/photo-1464226184884-fa280b87eee0?q=80&w=600&auto=format&fit=crop' },
    ];
    for (const n of newsItems) await ensureNews(n);
    console.log(`✅ ${newsItems.length} mandi news articles`);

    // ── Dealer Crop Rates ───────────────────────────────────
    const cropRates = [
        { dealerIdx: 0, cropName: 'Onion', pricePerQuintal: 2850, district: 'Nashik' },
        { dealerIdx: 0, cropName: 'Grapes', pricePerQuintal: 6200, district: 'Nashik' },
        { dealerIdx: 0, cropName: 'Soybean', pricePerQuintal: 4850, district: 'Nashik' },
        { dealerIdx: 0, cropName: 'Wheat', pricePerQuintal: 2275, district: 'Nashik' },
        { dealerIdx: 1, cropName: 'Tomato', pricePerQuintal: 1800, district: 'Pune' },
        { dealerIdx: 1, cropName: 'Onion', pricePerQuintal: 2900, district: 'Pune' },
        { dealerIdx: 1, cropName: 'Soybean', pricePerQuintal: 4900, district: 'Pune' },
        { dealerIdx: 1, cropName: 'Chilli', pricePerQuintal: 8500, district: 'Pune' },
    ];
    let rateCount = 0;
    for (const r of cropRates) {
        await prisma.dealerCropRate.upsert({
            where: {
                dealerId_cropName_district: {
                    dealerId: dealers[r.dealerIdx].dealer.id,
                    cropName: r.cropName,
                    district: r.district,
                },
            },
            update: { pricePerQuintal: r.pricePerQuintal, isActive: true },
            create: {
                dealerId: dealers[r.dealerIdx].dealer.id,
                cropName: r.cropName,
                pricePerQuintal: r.pricePerQuintal,
                district: r.district,
            },
        });
        rateCount++;
    }
    console.log(`✅ ${rateCount} dealer crop rates`);

    // ── Trade Bookings ──────────────────────────────────────
    const existingBookings = await prisma.tradeBooking.count();
    if (existingBookings === 0) {
        await prisma.tradeBooking.createMany({
            data: [
                { farmerId: farmers[0].farmer.id, dealerId: dealers[0].dealer.id, cropName: 'Onion', approxQuintals: 50, pricePerQuintal: 2800, slotDate: daysFromNow(3), status: 'PENDING', notes: 'Grade A Nashik Red' },
                { farmerId: farmers[0].farmer.id, dealerId: dealers[0].dealer.id, cropName: 'Grapes', approxQuintals: 20, pricePerQuintal: 6100, slotDate: daysFromNow(-2), status: 'COMPLETED', notes: 'Thompson seedless' },
                { farmerId: farmers[1].farmer.id, dealerId: dealers[0].dealer.id, cropName: 'Soybean', approxQuintals: 80, pricePerQuintal: 4800, slotDate: daysFromNow(5), status: 'ACCEPTED' },
                { farmerId: farmers[2].farmer.id, dealerId: dealers[1].dealer.id, cropName: 'Tomato', approxQuintals: 35, pricePerQuintal: 1750, slotDate: daysFromNow(2), status: 'PENDING' },
                { farmerId: farmers[2].farmer.id, dealerId: dealers[1].dealer.id, cropName: 'Chilli', approxQuintals: 12, pricePerQuintal: 8400, slotDate: daysFromNow(-5), status: 'COMPLETED' },
            ],
        });
        console.log('✅ 5 trade bookings');
    } else {
        console.log(`⏭️  Trade bookings already exist (${existingBookings}), skipped`);
    }

    // ── Cart ────────────────────────────────────────────────
    const [farmer0] = farmers;
    const cart = await prisma.cart.upsert({
        where: { farmerId: farmer0.farmer.id },
        update: {},
        create: { farmerId: farmer0.farmer.id },
    });
    const cartProducts = [products[0], products[4], products[8]];
    for (const [i, product] of cartProducts.entries()) {
        const existing = await prisma.cartItem.findFirst({ where: { cartId: cart.id, productId: product.id } });
        if (!existing) {
            await prisma.cartItem.create({ data: { cartId: cart.id, productId: product.id, quantity: i + 1 } });
        }
    }
    console.log('✅ Farmer cart with 3 items');

    // ── Orders ──────────────────────────────────────────────
    const existingOrders = await prisma.order.count();
    if (existingOrders === 0) {
        const order1Items = [
            { product: products[0], qty: 2, supplier: suppliers[0].supplier },
            { product: products[4], qty: 5, supplier: suppliers[0].supplier },
        ];
        const total1 = order1Items.reduce((s, i) => s + i.product.price * i.qty, 0);

        const order1 = await prisma.order.create({
            data: {
                farmerId: farmer0.farmer.id,
                totalAmount: total1,
                status: 'DELIVERED',
                paymentStatus: 'SUCCESS',
                paymentMethod: 'cod',
                deliveryAddress: 'Ramesh Patil, Niphad, Nashik 422303',
                deliveryLat: 20.08,
                deliveryLng: 74.10,
                deliveredAt: daysFromNow(-7),
                items: {
                    create: order1Items.map((i) => ({
                        productId: i.product.id,
                        supplierId: i.supplier.id,
                        quantity: i.qty,
                        price: i.product.price,
                        status: 'DELIVERED',
                    })),
                },
                payment: {
                    create: { amount: total1, status: 'SUCCESS', method: 'cod' },
                },
            },
            include: { items: true },
        });

        await prisma.review.create({
            data: {
                orderItemId: order1.items[0].id,
                productId: products[0].id,
                farmerId: farmer0.farmer.id,
                rating: 5,
                comment: 'Excellent quality DAP, delivered on time.',
            },
        });

        const order2Items = [{ product: products[8], qty: 3, supplier: suppliers[1].supplier }];
        const total2 = order2Items[0].product.price * order2Items[0].qty;

        await prisma.order.create({
            data: {
                farmerId: farmers[1].farmer.id,
                totalAmount: total2,
                status: 'DISPATCHED',
                paymentStatus: 'SUCCESS',
                paymentMethod: 'upi',
                utrNumber: 'UTR123456789012',
                deliveryAddress: 'Sunil Kadam, Sinnar, Nashik 422103',
                items: {
                    create: order2Items.map((i) => ({
                        productId: i.product.id,
                        supplierId: i.supplier.id,
                        quantity: i.qty,
                        price: i.product.price,
                        status: 'DISPATCHED',
                    })),
                },
                payment: {
                    create: { amount: total2, status: 'SUCCESS', method: 'upi' },
                },
            },
        });

        await prisma.order.create({
            data: {
                farmerId: farmers[2].farmer.id,
                totalAmount: products[9].price * 2,
                status: 'PENDING',
                paymentStatus: 'PENDING',
                paymentMethod: 'cod',
                deliveryAddress: 'Anita Deshmukh, Baramati, Pune 413102',
                items: {
                    create: [{
                        productId: products[9].id,
                        supplierId: suppliers[1].supplier.id,
                        quantity: 2,
                        price: products[9].price,
                    }],
                },
            },
        });
        console.log('✅ 3 orders (delivered, dispatched, pending) + 1 review');
    } else {
        console.log(`⏭️  Orders already exist (${existingOrders}), skipped`);
    }

    // ── Price Alerts ────────────────────────────────────────
    const alertDefs = [
        { farmerIdx: 0, cropName: 'Onion', targetPrice: 3000 },
        { farmerIdx: 0, cropName: 'Grapes', targetPrice: 6500 },
        { farmerIdx: 1, cropName: 'Soybean', targetPrice: 5000 },
        { farmerIdx: 2, cropName: 'Tomato', targetPrice: 2000 },
    ];
    for (const a of alertDefs) {
        const exists = await prisma.priceAlert.findFirst({
            where: { farmerId: farmers[a.farmerIdx].farmer.id, cropName: a.cropName },
        });
        if (!exists) {
            await prisma.priceAlert.create({
                data: { farmerId: farmers[a.farmerIdx].farmer.id, cropName: a.cropName, targetPrice: a.targetPrice },
            });
        }
    }
    console.log(`✅ ${alertDefs.length} price alerts`);

    // ── Soil Reports ────────────────────────────────────────
    const soilCount = await prisma.soilReport.count({ where: { farmerId: farmer0.farmer.id } });
    if (soilCount === 0) {
        await prisma.soilReport.create({
            data: {
                farmerId: farmer0.farmer.id,
                imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?q=80&w=600',
                soilType: 'Red-Black',
                phLevel: 6.8,
                nitrogenLevel: 'Medium',
                phosphorusLevel: 'Low',
                potassiumLevel: 'High',
                organicMatter: '2.1%',
                recommendedCrops: ['Onion', 'Grapes', 'Soybean'],
                treatmentAdvice: 'Apply DAP 50kg/acre before sowing. Add vermicompost 2 tonnes/acre.',
                confidence: 0.91,
            },
        });
        console.log('✅ 1 soil report');
    }

    // ── Notifications ───────────────────────────────────────
    const notifDefs = [
        { userId: farmers[0].user.id, title: 'Order Delivered', body: 'Your order #1 has been delivered successfully.', type: 'ORDER', isRead: true },
        { userId: farmers[0].user.id, title: 'Onion price alert', body: 'Onion rate at Nashik APMC crossed ₹2,850/quintal.', type: 'PRICE_ALERT', isRead: false },
        { userId: farmers[0].user.id, title: 'Trade booking accepted', body: 'Kisan Trading Co. accepted your soybean booking.', type: 'TRADE', isRead: false },
        { userId: suppliers[0].user.id, title: 'New order received', body: 'You have a new order for DAP Fertilizer x2.', type: 'ORDER', isRead: false },
        { userId: dealers[0].user.id, title: 'New trade request', body: 'Ramesh Patil wants to sell 50 quintals of Onion.', type: 'TRADE', isRead: false },
    ];
    let notifAdded = 0;
    for (const n of notifDefs) {
        const exists = await prisma.notification.findFirst({ where: { userId: n.userId, title: n.title } });
        if (!exists) {
            await prisma.notification.create({ data: n });
            notifAdded++;
        }
    }
    console.log(`✅ ${notifAdded} notifications`);

    console.log('\n🎉 Seed complete! AgriMart database is ready.');
    console.log('\nTest accounts (OTP: 123456):');
    console.log('  Farmer:   +919876543210  (Ramesh Patil)');
    console.log('  Farmer:   +919123456789  (Sunil Kadam)');
    console.log('  Supplier: +918765432109  (Suresh Agri Supplies)');
    console.log('  Dealer:   +917654321098  (Kisan Trading Co.)');
    console.log('  Admin:    +919999999999');
}

main()
    .catch((e) => { console.error(e); process.exit(1); })
    .finally(() => prisma.$disconnect());
