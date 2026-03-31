const twilio = require('twilio');
const logger = require('../utils/logger');

let client = null;
if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
    client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
}

const WHATSAPP_FROM = process.env.TWILIO_WHATSAPP_FROM || 'whatsapp:+14155238886';

const sendOrderConfirmation = async (order, farmer) => {
    if (!client) return;

    const itemsList = order.items
        .map(i => `• ${i.product.name} × ${i.quantity} = ₹${i.price * i.quantity}`)
        .join('\n');

    const message = `
✅ *Order Confirmed!*
Order ID: *#${order.id.slice(-6).toUpperCase()}*

📦 *Items:*
${itemsList}

💰 *Total paid:* ₹${order.totalAmount} (UPI/COD)
🚚 *Delivery:* Shortly by our delivery partners

📍 *Tracking:* Open AgriMart app → My Orders
📞 *Support:* Reply to this message

_AgriMart — शेतकऱ्यांचा विश्वासू बाजार_ 🌾
    `.trim();

    try {
        await client.messages.create({
            from: WHATSAPP_FROM,
            to: `whatsapp:+91${farmer.phone}`, // Assuming phone is 10 digits
            body: message,
        });
        logger.info(`WhatsApp order confirmation sent to ${farmer.phone}`);
    } catch (err) {
        logger.error(`Failed to send WhatsApp order confirmation: ${err.message}`);
    }
};

const sendDeliveryUpdate = async (order, farmer, status) => {
    if (!client) return;

    const messages = {
        DISPATCHED: `📦 Aapcha order #${order.id.slice(-6).toUpperCase()} dispatch zala!\n\nDelivery agent will reach you shortly.\n\nAgriMart app madhe track kara 🌾`,
        DELIVERED: `✅ Order delivered! 🎉\n\nKripaya AgriMart app madhe review dyaa — tumcha feedback aaplyasaathi mahatvaacha aahe!\n\nThank you for choosing AgriMart 🌾`,
        CANCELLED: `❌ Order #${order.id.slice(-6).toUpperCase()} cancel zala.\n\nRefund 3-5 business days madhe tumchya account madhye yeil.\n\nMore info: AgriMart app → My Orders`,
    };

    if (messages[status]) {
        try {
            await client.messages.create({
                from: WHATSAPP_FROM,
                to: `whatsapp:+91${farmer.phone}`,
                body: messages[status],
            });
            logger.info(`WhatsApp delivery update sent to ${farmer.phone}`);
        } catch (err) {
            logger.error(`Failed to send WhatsApp delivery update: ${err.message}`);
        }
    }
};

module.exports = { sendOrderConfirmation, sendDeliveryUpdate };
