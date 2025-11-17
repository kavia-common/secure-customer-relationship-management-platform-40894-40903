-- 0003_triggers.sql: Timestamp and audit triggers
SET ROLE appuser;

BEGIN;

-- Function to maintain updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

-- Generic audit function (basic)
CREATE OR REPLACE FUNCTION audit_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  rec_id BIGINT;
  summary JSONB;
BEGIN
  IF (TG_OP = 'INSERT') THEN
    rec_id := COALESCE((to_jsonb(NEW)->>'id')::BIGINT, NULL);
    summary := to_jsonb(NEW);
  ELSIF (TG_OP = 'UPDATE') THEN
    rec_id := COALESCE((to_jsonb(NEW)->>'id')::BIGINT, NULL);
    summary := to_jsonb(NEW);
  ELSIF (TG_OP = 'DELETE') THEN
    rec_id := COALESCE((to_jsonb(OLD)->>'id')::BIGINT, NULL);
    summary := to_jsonb(OLD);
  END IF;

  -- Remove sensitive fields if present
  summary := summary - 'password_hash' - 'salt' - 'secret';

  INSERT INTO audit_log (table_name, record_id, action, changed_by, change_summary)
  VALUES (TG_TABLE_NAME, rec_id, TG_OP, NULL, summary);

  IF (TG_OP = 'DELETE') THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$;

-- Attach timestamp triggers
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_users_set_updated_at') THEN
    CREATE TRIGGER trg_users_set_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_customers_set_updated_at') THEN
    CREATE TRIGGER trg_customers_set_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_sr_set_updated_at') THEN
    CREATE TRIGGER trg_sr_set_updated_at BEFORE UPDATE ON service_requests
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;
END
$$;

-- Attach audit triggers to key tables
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_users_audit') THEN
    CREATE TRIGGER trg_users_audit AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_changes();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_customers_audit') THEN
    CREATE TRIGGER trg_customers_audit AFTER INSERT OR UPDATE OR DELETE ON customers
    FOR EACH ROW EXECUTE FUNCTION audit_changes();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_sr_audit') THEN
    CREATE TRIGGER trg_sr_audit AFTER INSERT OR UPDATE OR DELETE ON service_requests
    FOR EACH ROW EXECUTE FUNCTION audit_changes();
  END IF;
END
$$;

COMMIT;
