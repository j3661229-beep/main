require('dotenv').config();
const orderService = require('../src/services/order.service');
const prisma = require('../src/config/database');

(async () => {
    const farmer = await prisma.farmer.findFirst({
        where: { user: { phone: '+919876543210' } },
    });
    if (!farmer) {
        console.log('No farmer found');
        process.exit(1);
    }
    try {
        const order = await orderService.createOrder(farmer.id, {
            deliveryAddress: 'Nashik test address',
            paymentMethod: 'cod',
        });
        console.log('ORDER OK', order.id, 'items', order.items.length);
    } catch (e) {
        console.log('ORDER FAIL', e.message);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
})();
