const cartService = require('../services/cart.service');
const { success } = require('../utils/apiResponse');

const getCart = async (req, res, next) => { try { success(res, await cartService.getCart(req.user.farmer.id)); } catch (e) { next(e); } };
const addItem = async (req, res, next) => { try { success(res, await cartService.addItem(req.user.farmer.id, req.body), 'Item added to cart'); } catch (e) { next(e); } };
const updateItem = async (req, res, next) => { try { success(res, await cartService.updateItem(req.user.farmer.id, req.params.itemId, req.body), 'Cart updated'); } catch (e) { next(e); } };
const removeItem = async (req, res, next) => { try { success(res, await cartService.removeItem(req.user.farmer.id, req.params.itemId), 'Item removed'); } catch (e) { next(e); } };
const clearCart = async (req, res, next) => { try { success(res, await cartService.clearCart(req.user.farmer.id), 'Cart cleared'); } catch (e) { next(e); } };

module.exports = { getCart, addItem, updateItem, removeItem, clearCart };
