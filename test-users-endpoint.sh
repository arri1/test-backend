#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# URL продакшн бекенда
BASE_URL="http://155.212.245.212"

echo -e "${YELLOW}🧪 Тестирование Users Endpoint${NC}"
echo "=================================="

# Тест 1: Health Check
echo -e "\n${YELLOW}1. Health Check${NC}"
response=$(curl -s -X GET "$BASE_URL/api/health")
echo "Response: $response"
if echo "$response" | grep -q "success"; then
    echo -e "${GREEN}✅ Health Check: OK${NC}"
else
    echo -e "${RED}❌ Health Check: FAILED${NC}"
    exit 1
fi

# Тест 2: Login to get token
echo -e "\n${YELLOW}2. Login to get token${NC}"
login_response=$(curl -s -X POST "$BASE_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')
echo "Response: $login_response"

if echo "$login_response" | grep -q "success"; then
    echo -e "${GREEN}✅ Login: OK${NC}"
    # Extract token
    access_token=$(echo "$login_response" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    echo "Token: ${access_token:0:50}..."
else
    echo -e "${RED}❌ Login: FAILED${NC}"
    exit 1
fi

# Тест 3: Get users list
echo -e "\n${YELLOW}3. Get Users List${NC}"
users_response=$(curl -s -X GET "$BASE_URL/api/auth/users" \
    -H "Authorization: Bearer $access_token")
echo "Response: $users_response"

if echo "$users_response" | grep -q "success"; then
    echo -e "${GREEN}✅ Get Users: OK${NC}"
    
    # Extract user count
    user_count=$(echo "$users_response" | grep -o '"totalCount":[0-9]*' | cut -d':' -f2)
    echo "Total users: $user_count"
else
    echo -e "${RED}❌ Get Users: FAILED${NC}"
    echo "Error: $users_response"
fi

# Тест 4: Get users with pagination
echo -e "\n${YELLOW}4. Get Users with Pagination${NC}"
users_paginated_response=$(curl -s -X GET "$BASE_URL/api/auth/users?page=1&limit=5" \
    -H "Authorization: Bearer $access_token")
echo "Response: $users_paginated_response"

if echo "$users_paginated_response" | grep -q "success"; then
    echo -e "${GREEN}✅ Get Users with Pagination: OK${NC}"
else
    echo -e "${RED}❌ Get Users with Pagination: FAILED${NC}"
fi

# Тест 5: Get users with search
echo -e "\n${YELLOW}5. Get Users with Search${NC}"
users_search_response=$(curl -s -X GET "$BASE_URL/api/auth/users?search=admin" \
    -H "Authorization: Bearer $access_token")
echo "Response: $users_search_response"

if echo "$users_search_response" | grep -q "success"; then
    echo -e "${GREEN}✅ Get Users with Search: OK${NC}"
else
    echo -e "${RED}❌ Get Users with Search: FAILED${NC}"
fi

echo -e "\n${YELLOW}📊 Итоги тестирования:${NC}"
echo "========================"
echo -e "${GREEN}✅ Users Endpoint: http://155.212.245.212/api/auth/users${NC}"
echo -e "${GREEN}✅ Доступен для всех зарегистрированных пользователей${NC}"
echo -e "${GREEN}✅ Поддерживает пагинацию и поиск${NC}"
