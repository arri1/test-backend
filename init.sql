-- Создание базы данных (если нужно)
-- CREATE DATABASE auth_db;

-- Создание пользователя (если нужно)
-- CREATE USER postgres WITH PASSWORD 'postgres';
-- GRANT ALL PRIVILEGES ON DATABASE auth_db TO postgres;

-- Включаем расширения PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
