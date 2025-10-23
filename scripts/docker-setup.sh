#!/bin/bash

echo "🐳 Setting up Docker environment for Auth Backend..."

# Проверяем, что Docker запущен
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Создаем .env файл если его нет
if [ ! -f .env ]; then
    echo "📝 Creating .env file from env.example..."
    cp env.example .env
    echo "✅ .env file created. Please update the database credentials if needed."
fi

# Останавливаем существующие контейнеры
echo "🛑 Stopping existing containers..."
docker-compose down

# Собираем образ
echo "🔨 Building Docker image..."
docker-compose build

# Запускаем только PostgreSQL
echo "🚀 Starting PostgreSQL..."
docker-compose up -d postgres

# Ждем пока PostgreSQL запустится
echo "⏳ Waiting for PostgreSQL to be ready..."
sleep 15

# Проверяем подключение к базе данных
echo "🔍 Testing database connection..."
until docker-compose exec postgres pg_isready -U postgres; do
    echo "⏳ Waiting for PostgreSQL..."
    sleep 2
done

echo "✅ PostgreSQL is ready!"

# Применяем миграции Prisma
echo "📊 Applying database migrations..."
npm run db:push

# Заполняем базу тестовыми данными
echo "🌱 Seeding database..."
npm run db:seed

echo "🎉 Docker setup completed successfully!"
echo ""
echo "📋 Available commands:"
echo "  npm run docker:up      - Start all services"
echo "  npm run docker:down    - Stop all services"
echo "  npm run docker:logs    - View logs"
echo "  npm run docker:restart - Restart services"
echo ""
echo "🔗 Services:"
echo "  Backend API: http://localhost:3000"
echo "  Prisma Studio: http://localhost:5555"
echo "  PostgreSQL: localhost:5432"
