const productService = require('../services/product.service');
const { success, created, paginated } = require('../utils/apiResponse');
const { getPagination } = require('../utils/helpers');

const getProducts = async (req, res, next) => {
    try {
        const pag = getPagination(req.query);
        const { products, total } = await productService.getProducts({ ...req.query, ...pag });
        paginated(res, products, pag.page, pag.limit, total);
    } catch (e) { next(e); }
};
const getProduct = async (req, res, next) => {
    try { success(res, await productService.getProduct(req.params.id)); } catch (e) { next(e); }
};
const getNearby = async (req, res, next) => {
    try { success(res, await productService.getNearby(req.query)); } catch (e) { next(e); }
};
const getNearbySuppliers = async (req, res, next) => {
    try { success(res, await productService.getNearbySuppliers(req.query)); } catch (e) { next(e); }
};
const getRecommended = async (req, res, next) => {
    try { success(res, await productService.getRecommended(req.user.farmer.id)); } catch (e) { next(e); }
};
const createProduct = async (req, res, next) => {
    try { created(res, await productService.createProduct(req.user.supplier.id, req.body)); } catch (e) { next(e); }
};
const updateProduct = async (req, res, next) => {
    try { success(res, await productService.updateProduct(req.user.supplier.id, req.params.id, req.body), 'Product updated'); } catch (e) { next(e); }
};
const deleteProduct = async (req, res, next) => {
    try { success(res, await productService.deleteProduct(req.user.supplier.id, req.params.id), 'Product removed'); } catch (e) { next(e); }
};
const uploadImages = async (req, res, next) => {
    try { success(res, await productService.uploadImages(req.user.supplier.id, req.params.id, req.files), 'Images uploaded'); } catch (e) { next(e); }
};
const getReviews = async (req, res, next) => {
    try { success(res, await productService.getReviews(req.params.id)); } catch (e) { next(e); }
};
const addReview = async (req, res, next) => {
    try { created(res, await productService.addReview(req.user.farmer.id, req.params.id, req.body)); } catch (e) { next(e); }
};

module.exports = {
    getProducts,
    getProduct,
    getNearby,
    getNearbySuppliers,
    getRecommended,
    createProduct,
    updateProduct,
    deleteProduct,
    uploadImages,
    getReviews,
    addReview
};
