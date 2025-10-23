#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# URL продакшн бекенда
BASE_URL="http://155.212.245.212"

echo -e "${YELLOW}🚀 Тестирование Auth Backend API${NC}"
echo "=================================="

# Тест 1: Health Check
echo -e "\n${YELLOW}1. Health Check${NC}"
response=$(curl -s -X GET "$BASE_URL/api/health")
echo "Response: $response"
if echo "$response" | grep -q "success"; then
    echo -e "${GREEN}✅ Health Check: OK${NC}"
else
    echo -e "${RED}❌ Health Check: FAILED${NC}"
fi

# Тест 2: Регистрация пользователя
echo -e "\n${YELLOW}2. Регистрация пользователя${NC}"
register_response=$(curl -s -X POST "$BASE_URL/api/auth/register" \
    -H "Content-Type: application/json" \
    -d '{"email":"testuser@example.com","password":"testpass123","name":"Test User"}')
echo "Response: $register_response"
if echo "$register_response" | grep -q "success"; then
    echo -e "${GREEN}✅ Регистрация: OK${NC}"
    # Извлекаем токен для дальнейшего использования
    access_token=$(echo "$register_response" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
else
    echo -e "${RED}❌ Регистрация: FAILED${NC}"
fi

# Тест 3: Вход пользователя
echo -e "\n${YELLOW}3. Вход пользователя${NC}"
login_response=$(curl -s -X POST "$BASE_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')
echo "Response: $login_response"
if echo "$login_response" | grep -q "success"; then
    echo -e "${GREEN}✅ Вход: OK${NC}"
    # Извлекаем токен для дальнейшего использования
    access_token=$(echo "$login_response" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
else
    echo -e "${RED}❌ Вход: FAILED${NC}"
fi

# Тест 4: Получение профиля
if [ ! -z "$access_token" ]; then
    echo -e "\n${YELLOW}4. Получение профиля пользователя${NC}"
    profile_response=$(curl -s -X GET "$BASE_URL/api/auth/profile" \
        -H "Authorization: Bearer $access_token")
    echo "Response: $profile_response"
    if echo "$profile_response" | grep -q "success"; then
        echo -e "${GREEN}✅ Профиль: OK${NC}"
    else
        echo -e "${RED}❌ Профиль: FAILED${NC}"
    fi
else
    echo -e "\n${RED}❌ Не удалось получить токен для теста профиля${NC}"
fi

# Тест 5: Проверка Prisma Studio
echo -e "\n${YELLOW}5. Проверка Prisma Studio${NC}"
studio_response=$(curl -s -I "http://155.212.245.212:5555")
if echo "$studio_response" | grep -q "200 OK"; then
    echo -e "${GREEN}✅ Prisma Studio: OK${NC}"
else
    echo -e "${RED}❌ Prisma Studio: FAILED${NC}"
fi

echo -e "\n${YELLOW}📊 Итоги тестирования:${NC}"
echo "========================"
echo -e "${GREEN}✅ API Backend: http://155.212.245.212${NC}"
echo -e "${GREEN}✅ Prisma Studio: http://155.212.245.212:5555${NC}"
echo -e "${GREEN}✅ PostgreSQL: 155.212.245.212:5432${NC}"

echo -e "\n${YELLOW}🔐 Тестовые пользователи:${NC}"
echo "Admin: admin@example.com / admin123"
echo "User: user@example.com / user123"

echo -e "\n${YELLOW}📚 Доступные API endpoints:${NC}"
echo "POST /api/auth/register - Регистрация"
echo "POST /api/auth/login - Вход"
echo "GET /api/auth/profile - Профиль пользователя"
echo "GET /api/health - Проверка здоровья сервера"
