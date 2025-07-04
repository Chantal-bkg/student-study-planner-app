const express = require('express');
const router = express.Router();
const reminderController = require('../controllers/reminderController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

router.post('/', authMiddleware, reminderController.createReminder);
router.get('/', authMiddleware, reminderController.getAllTReminder);
router.delete('/:id', authMiddleware, reminderController.deleteReminder);

module.exports = router;