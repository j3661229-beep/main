const express = require('express');
const { getNews, createNews } = require('../controllers/news.controller');

const router = express.Router();

router.get('/', getNews);
router.post('/', createNews);

module.exports = router;

