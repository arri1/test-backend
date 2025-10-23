const express = require('express');
const router = express.Router();
const authRoutes = require('./auth');

// Основные маршруты
router.use('/auth', authRoutes);

// Тестовый маршрут
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
