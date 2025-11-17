-- 0000_enable_extensions.sql: Enable required PostgreSQL extensions before schema creation
-- This file must run before any migration using CITEXT.
-- It is safe to run multiple times due to IF NOT EXISTS.

-- Enable case-insensitive text support
CREATE EXTENSION IF NOT EXISTS citext;
