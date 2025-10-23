const prisma = require('../config/database');
const { hashPassword, comparePassword } = require('../utils/password');
const { generateTokens, verifyRefreshToken } = require('../utils/jwt');
const { JWT_REFRESH_EXPIRES_IN } = require('../config/env');

const register = async (req, res) => {
  try {
    const { email, password, name } = req.body;

    // Проверяем, существует ли пользователь
    const existingUser = await prisma.user.findUnique({
      where: { email }
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    // Хешируем пароль
    const hashedPassword = await hashPassword(password);

    // Создаем пользователя
    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name: name || null
      },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        createdAt: true
      }
    });

    // Генерируем токены
    const { accessToken, refreshToken } = generateTokens(user.id);

    // Сохраняем refresh token в базе данных
    const expiresAt = new Date(Date.now() + parseInt(JWT_REFRESH_EXPIRES_IN.replace('d', '')) * 24 * 60 * 60 * 1000);
    await prisma.refreshToken.create({
      data: {
        token: refreshToken,
        userId: user.id,
        expiresAt
      }
    });

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user,
        accessToken,
        refreshToken
      }
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Находим пользователя
    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Проверяем пароль
    const isPasswordValid = await comparePassword(password, user.password);

    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Генерируем токены
    const { accessToken, refreshToken } = generateTokens(user.id);

    // Удаляем старые refresh токены пользователя
    await prisma.refreshToken.deleteMany({
      where: { userId: user.id }
    });

    // Сохраняем новый refresh token
    const expiresAt = new Date(Date.now() + parseInt(JWT_REFRESH_EXPIRES_IN.replace('d', '')) * 24 * 60 * 60 * 1000);
    await prisma.refreshToken.create({
      data: {
        token: refreshToken,
        userId: user.id,
        expiresAt
      }
    });

    // Возвращаем данные пользователя без пароля
    const { password: _, ...userWithoutPassword } = user;

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: userWithoutPassword,
        accessToken,
        refreshToken
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

const refresh = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    // Проверяем refresh token в базе данных
    const tokenRecord = await prisma.refreshToken.findUnique({
      where: { token: refreshToken },
      include: { user: true }
    });

    if (!tokenRecord) {
      return res.status(401).json({
        success: false,
        message: 'Invalid refresh token'
      });
    }

    // Проверяем срок действия
    if (tokenRecord.expiresAt < new Date()) {
      await prisma.refreshToken.delete({
        where: { token: refreshToken }
      });
      return res.status(401).json({
        success: false,
        message: 'Refresh token expired'
      });
    }

    // Верифицируем токен
    const decoded = verifyRefreshToken(refreshToken);

    // Генерируем новые токены
    const { accessToken, refreshToken: newRefreshToken } = generateTokens(decoded.userId);

    // Удаляем старый refresh token
    await prisma.refreshToken.delete({
      where: { token: refreshToken }
    });

    // Сохраняем новый refresh token
    const expiresAt = new Date(Date.now() + parseInt(JWT_REFRESH_EXPIRES_IN.replace('d', '')) * 24 * 60 * 60 * 1000);
    await prisma.refreshToken.create({
      data: {
        token: newRefreshToken,
        userId: decoded.userId,
        expiresAt
      }
    });

    res.json({
      success: true,
      message: 'Tokens refreshed successfully',
      data: {
        accessToken,
        refreshToken: newRefreshToken
      }
    });

  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(401).json({
      success: false,
      message: 'Invalid refresh token'
    });
  }
};

const logout = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (refreshToken) {
      // Удаляем refresh token из базы данных
      await prisma.refreshToken.deleteMany({
        where: { token: refreshToken }
      });
    }

    res.json({
      success: true,
      message: 'Logout successful'
    });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

const getProfile = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        createdAt: true,
        updatedAt: true
      }
    });

    res.json({
      success: true,
      data: { user }
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

const getUsers = async (req, res) => {
  try {
    const { page = 1, limit = 10, role, search } = req.query;
    const offset = (page - 1) * limit;

    // Строим условия для фильтрации
    const where = {};
    
    if (role) {
      where.role = role;
    }
    
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } }
      ];
    }

    // Получаем пользователей с пагинацией
    const [users, totalCount] = await Promise.all([
      prisma.user.findMany({
        where,
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
          createdAt: true,
          updatedAt: true
        },
        orderBy: { createdAt: 'desc' },
        skip: parseInt(offset),
        take: parseInt(limit)
      }),
      prisma.user.count({ where })
    ]);

    const totalPages = Math.ceil(totalCount / limit);

    res.json({
      success: true,
      data: {
        users,
        pagination: {
          currentPage: parseInt(page),
          totalPages,
          totalCount,
          limit: parseInt(limit),
          hasNext: page < totalPages,
          hasPrev: page > 1
        }
      }
    });

  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

module.exports = {
  register,
  login,
  refresh,
  logout,
  getProfile,
  getUsers
};
