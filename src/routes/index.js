const express = require('express');
const router = express.Router();
const authRoutes = require('./auth');

// Основные маршруты
router.use('/auth', authRoutes);

/**
 * @swagger
 * /health:
 *   get:
 *     summary: Проверка состояния сервера
 *     tags: [Health]
 *     responses:
 *       200:
 *         description: Сервер работает
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/HealthResponse'
 */
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
