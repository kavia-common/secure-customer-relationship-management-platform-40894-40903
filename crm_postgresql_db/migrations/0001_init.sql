-- 0001_init.sql: Initial schema for CRM
-- Ensure objects are owned by the app user (matches startup.sh DB_USER)
SET ROLE appuser;

BEGIN;

-- Core tables

CREATE TABLE IF NOT EXISTS users (
    id            BIGSERIAL PRIMARY KEY,
    email         CITEXT UNIQUE NOT NULL,
    full_name     TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Roles and RBAC

CREATE TABLE IF NOT EXISTS roles (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, role_id)
);

-- Customers

CREATE TABLE IF NOT EXISTS customers (
    id          BIGSERIAL PRIMARY KEY,
    external_id TEXT,
    name        TEXT NOT NULL,
    email       CITEXT,
    phone       TEXT,
    address     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_customers_external_id UNIQUE (external_id)
);

-- Service Requests / Complaints

CREATE TABLE IF NOT EXISTS service_requests (
    id           BIGSERIAL PRIMARY KEY,
    customer_id  BIGINT NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    title        TEXT NOT NULL,
    description  TEXT,
    status       TEXT NOT NULL DEFAULT 'open',
    priority     SMALLINT NOT NULL DEFAULT 3, -- 1 highest, 5 lowest
    assigned_to  BIGINT REFERENCES users(id) ON DELETE SET NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_service_requests_status CHECK (status IN ('open','in_progress','closed')),
    CONSTRAINT ck_service_requests_priority CHECK (priority BETWEEN 1 AND 5)
);

-- Minimal interactions table (omni-channel placeholder)

CREATE TABLE IF NOT EXISTS interactions (
    id             BIGSERIAL PRIMARY KEY,
    customer_id    BIGINT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    channel        TEXT NOT NULL, -- e.g., 'phone','email','social','bot'
    direction      TEXT NOT NULL, -- 'inbound' | 'outbound'
    content        TEXT,
    occurred_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Audit log

CREATE TABLE IF NOT EXISTS audit_log (
    id            BIGSERIAL PRIMARY KEY,
    table_name    TEXT NOT NULL,
    record_id     BIGINT,
    action        TEXT NOT NULL, -- INSERT | UPDATE | DELETE
    changed_by    BIGINT REFERENCES users(id) ON DELETE SET NULL,
    changed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    change_summary JSONB
);

COMMIT;

-- Helpful note: CITEXT requires extension; to avoid external dependencies you can remove CITEXT or ensure it's available.
-- If CITEXT extension is not available in your environment, run:
--   ALTER TABLE users ALTER COLUMN email TYPE TEXT;
--   ALTER TABLE customers ALTER COLUMN email TYPE TEXT;
