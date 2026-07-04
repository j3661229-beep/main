const express = require('express');
const { getNews, createNews, syncGoogleNews } = require('../controllers/news.controller');

const router = express.Router();

router.get('/', getNews);
router.post('/', createNews);
router.post('/sync', syncGoogleNews);

module.exports = router;
