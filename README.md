# Authentication Backend

Backend для авторизации с использованием Prisma, PostgreSQL и Node.js.

## 🚀 Возможности

- Регистрация пользователей
- Вход в систему
- JWT токены (access + refresh)
- Защищенные маршруты
- Валидация данных
- Rate limiting
- Безопасность (Helmet, CORS)
- Роли пользователей (USER, ADMIN)

## 📋 Требования

### Для локальной разработки:
- Node.js (v16 или выше)
- PostgreSQL
- npm или yarn

### Для Docker:
- Docker
- Docker Compose

## 🛠 Установка

### 🐳 Быстрый запуск с Docker (рекомендуется)

1. **Клонируйте репозиторий:**
   ```bash
   git clone <repository-url>
   cd test-backend
   ```

2. **Автоматическая настройка с Docker:**
   ```bash
   # Запустите скрипт автоматической настройки
   ./scripts/docker-setup.sh
   ```

   Или выполните команды вручную:
   ```bash
   # Создайте .env файл
   cp env.example .env
   
   # Запустите только PostgreSQL
   docker-compose up -d postgres
   
   # Подождите 10 секунд и инициализируйте базу данных
   npm run db:push
   npm run db:seed
   
   # Запустите все сервисы
   docker-compose up -d
   ```

3. **Доступные сервисы:**
   - Backend API: http://localhost:3000
   - Prisma Studio: http://localhost:5555
   - PostgreSQL: localhost:5432

### 💻 Локальная установка

1. **Установите зависимости:**
   ```bash
   npm install
   ```

2. **Настройте базу данных:**
   - Создайте базу данных PostgreSQL
   - Скопируйте `env.example` в `.env`
   - Обновите `DATABASE_URL` в `.env` файле

3. **Настройте переменные окружения в `.env`:**
   ```env
   DATABASE_URL="postgresql://username:password@localhost:5432/auth_db?schema=public"
   JWT_SECRET="your-super-secret-jwt-key-here"
   JWT_REFRESH_SECRET="your-super-secret-refresh-key-here"
   JWT_EXPIRES_IN="15m"
   JWT_REFRESH_EXPIRES_IN="7d"
   PORT=3000
   NODE_ENV="development"
   CORS_ORIGIN="http://localhost:3000"
   ```

4. **Инициализируйте базу данных:**
   ```bash
   # Генерируем Prisma клиент
   npm run db:generate
   
   # Применяем миграции
   npm run db:push
   
   # Заполняем базу тестовыми данными
   npm run db:seed
   ```

5. **Запустите сервер:**
   ```bash
   # Для разработки
   npm run dev
   
   # Для продакшена
   npm start
   ```

## 📚 API Endpoints

### Аутентификация

- `POST /api/auth/register` - Регистрация пользователя
- `POST /api/auth/login` - Вход в систему
- `POST /api/auth/refresh` - Обновление токенов
- `POST /api/auth/logout` - Выход из системы
- `GET /api/auth/profile` - Получение профиля пользователя (требует токен)

### Другие

- `GET /api/health` - Проверка состояния сервера

## 📝 Примеры использования

### Регистрация
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User"
  }'
```

### Вход
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Получение профиля
```bash
curl -X GET http://localhost:3000/api/auth/profile \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## 🔧 Скрипты

### Основные команды
- `npm start` - Запуск сервера
- `npm run dev` - Запуск в режиме разработки
- `npm run db:generate` - Генерация Prisma клиента
- `npm run db:push` - Применение изменений схемы
- `npm run db:migrate` - Создание миграций
- `npm run db:studio` - Открытие Prisma Studio
- `npm run db:seed` - Заполнение базы тестовыми данными

### Docker команды
- `npm run docker:build` - Сборка Docker образа
- `npm run docker:up` - Запуск всех сервисов в Docker
- `npm run docker:down` - Остановка всех сервисов
- `npm run docker:logs` - Просмотр логов
- `npm run docker:restart` - Перезапуск сервисов
- `npm run docker:setup` - Автоматическая настройка с PostgreSQL

### Docker Compose команды
```bash
# Запуск всех сервисов
docker-compose up -d

# Запуск только PostgreSQL (для разработки)
docker-compose up -d postgres

# Запуск с пересборкой
docker-compose up --build

# Остановка всех сервисов
docker-compose down

# Просмотр логов
docker-compose logs -f

# Перезапуск сервисов
docker-compose restart
```

## 🗄️ Структура базы данных

### Users
- `id` - Уникальный идентификатор
- `email` - Email пользователя (уникальный)
- `password` - Хешированный пароль
- `name` - Имя пользователя
- `role` - Роль (USER/ADMIN)
- `createdAt` - Дата создания
- `updatedAt` - Дата обновления

### RefreshTokens
- `id` - Уникальный идентификатор
- `token` - Refresh токен
- `userId` - ID пользователя
- `expiresAt` - Дата истечения
- `createdAt` - Дата создания

## 🔒 Безопасность

- Пароли хешируются с помощью bcrypt
- JWT токены для аутентификации
- Refresh токены для обновления access токенов
- Rate limiting для предотвращения атак
- Валидация входных данных
- CORS настройки
- Helmet для безопасности заголовков

## 🧪 Тестовые пользователи

После выполнения `npm run db:seed` создаются тестовые пользователи:

- **Админ:** email: `admin@example.com`, пароль: `admin123`
- **Пользователь:** email: `user@example.com`, пароль: `user123`

## 📁 Структура проекта

```
src/
├── config/          # Конфигурация (база данных, переменные окружения)
├── controllers/     # Контроллеры
├── middleware/      # Middleware (аутентификация, валидация)
├── routes/          # Маршруты API
├── utils/           # Утилиты (JWT, пароли)
└── server.js        # Главный файл сервера

prisma/
├── schema.prisma    # Схема базы данных
└── seed.js          # Заполнение тестовыми данными
```
