const Razorpay = require('razorpay');

let razorpay;

if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
    razorpay = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET,
    });
} else {
    // Mock for development
    razorpay = {
        orders: {
            create: async (opts) => ({
                id: `order_mock_${Date.now()}`,
                amount: opts.amount,
                currency: opts.currency,
                status: 'created',
            }),
        },
        payments: {
            refund: async (paymentId, opts) => ({
                id: `refund_mock_${Date.now()}`,
                payment_id: paymentId,
                amount: opts.amount,
                status: 'processed',
            }),
        },
    };
}

module.exports = razorpay;
