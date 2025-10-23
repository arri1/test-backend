#!/bin/bash

# Быстрое развертывание на VPS
# Запускать на сервере: curl -sSL https://raw.githubusercontent.com/arri1/test-backend/main/deploy.sh | bash

echo "🚀 Быстрое развертывание Auth Backend..."

# Обновляем систему
apt update && apt upgrade -y

# Устанавливаем Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm get-docker.sh

# Устанавливаем Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Устанавливаем Nginx и Certbot
apt install -y nginx certbot python3-certbot-nginx git

# Создаем директорию и клонируем репозиторий
mkdir -p /opt/auth-backend && cd /opt/auth-backend
git clone https://github.com/arri1/test-backend.git .

# Создаем .env файл
cat > .env << EOF
DATABASE_URL="postgresql://postgres:postgres@postgres:5432/auth_db?schema=public"
JWT_SECRET="$(openssl rand -base64 32)"
JWT_REFRESH_SECRET="$(openssl rand -base64 32)"
JWT_EXPIRES_IN="15m"
JWT_REFRESH_EXPIRES_IN="7d"
PORT=3000
NODE_ENV="production"
CORS_ORIGIN="https://cloud.kit-imi.info"
EOF

# Настраиваем Nginx
cat > /etc/nginx/sites-available/auth-backend << 'EOF'
server {
    listen 80;
    server_name cloud.kit-imi.info;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

ln -sf /etc/nginx/sites-available/auth-backend /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Запускаем приложение
docker-compose -f docker-compose.prod.yml up -d

# Ждем запуска и инициализируем БД
sleep 30
docker-compose -f docker-compose.prod.yml exec app npm run db:push
docker-compose -f docker-compose.prod.yml exec app npm run db:seed

# Настраиваем SSL
certbot --nginx -d cloud.kit-imi.info --non-interactive --agree-tos --email admin@kit-imi.info

echo "✅ Развертывание завершено! Приложение доступно на https://cloud.kit-imi.info"
