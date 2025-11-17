-- 0002_constraints_indexes.sql: Indexes and additional constraints
SET ROLE appuser;

BEGIN;

-- Users
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users (email);

-- Customers
CREATE INDEX IF NOT EXISTS idx_customers_name ON customers (name);
CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_email ON customers (email);
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
