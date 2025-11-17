-- 0001_init.sql: Initial schema for CRM
-- Ensures citext usage when available, with TEXT fallback via a domain type.
SET ROLE appuser;

-- Informational check for citext availability
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='citext') THEN
    RAISE NOTICE 'citext not available, using TEXT fallback';
  END IF;
END
$$;

-- Create a domain ci_text that maps to citext when available otherwise text
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ci_text') THEN
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname='citext') THEN
      EXECUTE 'CREATE DOMAIN ci_text AS citext';
    ELSE
      EXECUTE 'CREATE DOMAIN ci_text AS text';
    END IF;
  END IF;
END
$$;

BEGIN;

-- Core tables

CREATE TABLE IF NOT EXISTS users (
    id            BIGSERIAL PRIMARY KEY,
    email         ci_text UNIQUE NOT NULL,
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
    email       ci_text,
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

-- Note:
-- - The ci_text domain ensures portability: it uses citext if available, otherwise text.
-- - For environments without citext, case-insensitive uniqueness is enforced via functional indexes in 0002.
