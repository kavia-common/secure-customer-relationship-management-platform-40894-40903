-- 0002_constraints_indexes.sql: Indexes and additional constraints
SET ROLE appuser;

BEGIN;

-- Users: unique email - citext path uses direct unique; fallback uses functional unique on lower(email)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname='citext') THEN
    -- citext ensures case-insensitive semantics
    EXECUTE 'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users (email)';
  ELSE
    -- fallback: enforce case-insensitive uniqueness via functional index
    EXECUTE 'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_ci ON users (LOWER(email))';
  END IF;
END
$$;

-- Customers: email unique handling as above
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname='citext') THEN
    EXECUTE 'CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_email ON customers (email)';
  ELSE
    EXECUTE 'CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_email_ci ON customers (LOWER(email))';
  END IF;
END
$$;

-- Customers - additional indexes
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers (name);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers (phone);

-- Service Requests
CREATE INDEX IF NOT EXISTS idx_sr_customer ON service_requests (customer_id);
CREATE INDEX IF NOT EXISTS idx_sr_status ON service_requests (status);
CREATE INDEX IF NOT EXISTS idx_sr_assigned ON service_requests (assigned_to);
CREATE INDEX IF NOT EXISTS idx_sr_priority ON service_requests (priority);

-- Interactions
CREATE INDEX IF NOT EXISTS idx_interactions_customer ON interactions (customer_id);
CREATE INDEX IF NOT EXISTS idx_interactions_channel ON interactions (channel);
CREATE INDEX IF NOT EXISTS idx_interactions_occurred_at ON interactions (occurred_at);

-- Audit log
CREATE INDEX IF NOT EXISTS idx_audit_table_record ON audit_log (table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_audit_changed_at ON audit_log (changed_at);

COMMIT;
