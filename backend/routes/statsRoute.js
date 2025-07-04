const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const statsController = require('../controllers/statsController');

router.get('/weekly', authMiddleware, statsController.getWeeklyStats);

module.exports = router;