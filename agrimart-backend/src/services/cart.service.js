const prisma = require('../config/database');

const getCart = async (farmerId) => {
    let cart = await prisma.cart.findUnique({
        where: { farmerId },
        include: { items: { include: { product: { include: { supplier: { include: { user: true } } } } } } },
    });
    if (!cart) cart = await prisma.cart.create({ data: { farmerId }, include: { items: true } });
    return cart;
};

const addItem = async (farmerId, { productId, quantity }) => {
    let cart = await prisma.cart.findUnique({ where: { farmerId } });
    if (!cart) cart = await prisma.cart.create({ data: { farmerId } });

    const product = await prisma.product.findUnique({ where: { id: productId } });
    if (!product || !product.isActive) throw Object.assign(new Error('Product not available'), { statusCode: 400 });
    if (product.stockQuantity < quantity) throw Object.assign(new Error('Insufficient stock'), { statusCode: 400 });

    const existing = await prisma.cartItem.findFirst({ where: { cartId: cart.id, productId } });
    if (existing) {
        await prisma.cartItem.update({ where: { id: existing.id }, data: { quantity: existing.quantity + parseInt(quantity) } });
    } else {
        await prisma.cartItem.create({ data: { cartId: cart.id, productId, quantity: parseInt(quantity) } });
    }
    return getCart(farmerId);
};

const updateItem = async (farmerId, itemId, { quantity }) => {
    const cart = await prisma.cart.findUnique({ where: { farmerId } });
    if (!cart) throw Object.assign(new Error('Cart not found'), { statusCode: 404 });
    const item = await prisma.cartItem.findFirst({ where: { id: itemId, cartId: cart.id } });
    if (!item) throw Object.assign(new Error('Item not found'), { statusCode: 404 });

    if (quantity <= 0) {
        await prisma.cartItem.delete({ where: { id: itemId } });
    } else {
        await prisma.cartItem.update({ where: { id: itemId }, data: { quantity: parseInt(quantity) } });
    }
    return getCart(farmerId);
};

const removeItem = async (farmerId, itemId) => {
    const cart = await prisma.cart.findUnique({ where: { farmerId } });
    if (!cart) throw Object.assign(new Error('Cart not found'), { statusCode: 404 });
    await prisma.cartItem.deleteMany({ where: { id: itemId, cartId: cart.id } });
    return getCart(farmerId);
};

const clearCart = async (farmerId) => {
    const cart = await prisma.cart.findUnique({ where: { farmerId } });
    if (cart) await prisma.cartItem.deleteMany({ where: { cartId: cart.id } });
    return { message: 'Cart cleared' };
};

module.exports = { getCart, addItem, updateItem, removeItem, clearCart };
