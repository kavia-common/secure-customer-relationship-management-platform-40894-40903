-- 0000_enable_extensions.sql: Enable required PostgreSQL extensions before schema creation
-- This file must run before any migration using CITEXT.
-- It is safe to run multiple times and will not fail if the extension cannot be installed.

-- Attempt to enable case-insensitive text support (citext).
-- If permissions or availability prevent enabling, log a notice and proceed with TEXT fallback in later migrations.
DO $$
BEGIN
  BEGIN
    EXECUTE 'CREATE EXTENSION IF NOT EXISTS citext';
    RAISE NOTICE 'citext extension enabled or already present';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'citext extension could not be enabled due to insufficient privileges; proceeding with TEXT fallback.';
    WHEN undefined_file THEN
      RAISE NOTICE 'citext extension is not available on this server; proceeding with TEXT fallback.';
    WHEN OTHERS THEN
      RAISE NOTICE 'citext extension could not be enabled (error: %); proceeding with TEXT fallback.', SQLERRM;
  END;
END
$$;
