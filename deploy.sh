#!/bin/bash

# Скрипт развертывания Auth Backend на Ubuntu 24.04 VPS
# Запускать от имени root на сервере

set -e

echo "🚀 Начинаем развертывание Auth Backend на VPS..."

# Обновляем систему
echo "📦 Обновляем систему..."
apt update && apt upgrade -y

# Устанавливаем необходимые пакеты
echo "🔧 Устанавливаем необходимые пакеты..."
apt install -y curl wget git nginx certbot python3-certbot-nginx ufw

# Устанавливаем Docker
echo "🐳 Устанавливаем Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Устанавливаем Docker Compose
echo "🐳 Устанавливаем Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Запускаем Docker
systemctl start docker
systemctl enable docker

# Создаем директорию для приложения
echo "📁 Создаем директорию для приложения..."
mkdir -p /opt/auth-backend
cd /opt/auth-backend

# Клонируем репозиторий
echo "📥 Клонируем репозиторий..."
git clone https://github.com/arri1/test-backend.git .

# Создаем .env файл для продакшена
echo "⚙️ Настраиваем переменные окружения..."
cat > .env << EOF
# Database
DATABASE_URL="postgresql://postgres:postgres@postgres:5432/auth_db?schema=public"

# JWT
JWT_SECRET="$(openssl rand -base64 32)"
JWT_REFRESH_SECRET="$(openssl rand -base64 32)"
JWT_EXPIRES_IN="15m"
JWT_REFRESH_EXPIRES_IN="7d"

# Server
PORT=3000
NODE_ENV="production"

# CORS
CORS_ORIGIN="https://cloud.kit-imi.info"
EOF

# Настраиваем firewall
echo "🔥 Настраиваем firewall..."
ufw allow ssh
ufw allow 80
ufw allow 443
ufw --force enable

# Создаем конфигурацию Nginx
echo "🌐 Настраиваем Nginx..."
cat > /etc/nginx/sites-available/auth-backend << EOF
server {
    listen 80;
    server_name cloud.kit-imi.info;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Активируем конфигурацию Nginx
ln -sf /etc/nginx/sites-available/auth-backend /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Проверяем конфигурацию Nginx
nginx -t

# Перезапускаем Nginx
systemctl restart nginx
systemctl enable nginx

# Запускаем приложение
echo "🚀 Запускаем приложение..."
docker-compose up -d

# Ждем запуска сервисов
echo "⏳ Ждем запуска сервисов..."
sleep 30

# Применяем миграции и заполняем базу данных
echo "📊 Инициализируем базу данных..."
docker-compose exec app npm run db:push
docker-compose exec app npm run db:seed

# Получаем SSL сертификат
echo "🔒 Настраиваем SSL сертификат..."
certbot --nginx -d cloud.kit-imi.info --non-interactive --agree-tos --email admin@kit-imi.info

# Настраиваем автообновление сертификата
echo "🔄 Настраиваем автообновление SSL..."
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -

echo "✅ Развертывание завершено!"
echo ""
echo "🌐 Ваше приложение доступно по адресу: https://cloud.kit-imi.info"
echo "📊 Prisma Studio: https://cloud.kit-imi.info:5555"
echo ""
echo "📋 Полезные команды:"
echo "  docker-compose logs -f          # Просмотр логов"
echo "  docker-compose restart          # Перезапуск сервисов"
echo "  docker-compose down             # Остановка сервисов"
echo "  docker-compose up -d            # Запуск сервисов"
echo ""
echo "🔑 Тестовые пользователи:"
echo "  Админ: admin@example.com / admin123"
echo "  Пользователь: user@example.com / user123"
