-- 0004_seed.sql: Seed minimal data for CRM
SET ROLE appuser;

BEGIN;

-- Roles
INSERT INTO roles (name, description) VALUES
  ('admin', 'System administrator with full access'),
  ('agent', 'Service agent with customer handling permissions')
ON CONFLICT (name) DO NOTHING;

-- Admin user with PBKDF2 placeholder (replace during real provisioning)
-- Format is a placeholder; backend should validate/replace with real PBKDF2 hash.
INSERT INTO users (email, full_name, password_hash, is_active)
VALUES ('admin@local', 'Administrator', 'pbkdf2_sha256$260000$REPLACE_SALT$REPLACE_HASH', true)
ON CONFLICT (email) DO NOTHING;

-- Assign admin role to admin user
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
JOIN roles r ON r.name = 'admin'
WHERE u.email = 'admin@local'
ON CONFLICT DO NOTHING;

-- Sample customers
INSERT INTO customers (external_id, name, email, phone, address)
VALUES 
  ('CUST-001', 'Acme Corp', 'contact@acme.example', '+1-202-555-0101', '1 Infinite Loop, Springfield'),
  ('CUST-002', 'Globex Inc', 'info@globex.example', '+1-202-555-0112', '42 Galaxy Way, Metropolis')
ON CONFLICT (external_id) DO NOTHING;

-- Sample service requests linked to customers
INSERT INTO service_requests (customer_id, title, description, status, priority, assigned_to)
SELECT c.id, 'Onboarding assistance', 'Need help setting up initial configuration', 'open', 2, u.id
FROM customers c CROSS JOIN LATERAL (SELECT id FROM users WHERE email = 'admin@local' LIMIT 1) u
WHERE c.external_id = 'CUST-001'
ON CONFLICT DO NOTHING;

INSERT INTO service_requests (customer_id, title, description, status, priority, assigned_to)
SELECT c.id, 'Billing inquiry', 'Question about invoice #INV-12345', 'in_progress', 3, u.id
FROM customers c CROSS JOIN LATERAL (SELECT id FROM users WHERE email = 'admin@local' LIMIT 1) u
WHERE c.external_id = 'CUST-002'
ON CONFLICT DO NOTHING;

COMMIT;
