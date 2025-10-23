const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticateToken } = require('../middleware/auth');
const { requireRole } = require('../middleware/role');
const { validateRegister, validateLogin, validateRefreshToken } = require('../middleware/validation');

// Публичные маршруты
router.post('/register', validateRegister, authController.register);
router.post('/login', validateLogin, authController.login);
router.post('/refresh', validateRefreshToken, authController.refresh);
router.post('/logout', authController.logout);

// Защищенные маршруты
router.get('/profile', authenticateToken, authController.getProfile);
router.get('/users', authenticateToken, authController.getUsers);

module.exports = router;
