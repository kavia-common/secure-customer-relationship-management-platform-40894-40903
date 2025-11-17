# secure-customer-relationship-management-platform-40894-40903

## Database Migrations (PostgreSQL)

This repository includes a lightweight SQL-based migration runner for the CRM database located at:
- `crm_postgresql_db/run_migrations.sh`
- SQL migrations in `crm_postgresql_db/migrations/`

### Important: citext Extension

The schema uses CITEXT (case-insensitive text) for user and customer email columns. To ensure migrations succeed, we added a dedicated migration that enables the extension before any table definitions that use it.

- New file: `crm_postgresql_db/migrations/0000_enable_extensions.sql`
  - Content: `CREATE EXTENSION IF NOT EXISTS citext;`
  - Idempotent: Uses `IF NOT EXISTS`
  - Runs without `SET ROLE` so it executes with superuser privileges (the migration runner invokes psql as the `postgres` system user), which is required for enabling extensions.

### Migration Order

The migration runner applies files in lexicographic order. This guarantees that `0000_enable_extensions.sql` runs before `0001_init.sql`, which uses CITEXT. Ordering is handled by the script’s sort step:

- `run_migrations.sh` collects `*.sql` and applies them in sorted lexical order.

### How to Run

The startup script and migration runner will:
1. Ensure Postgres is running on the configured port.
2. Ensure the `app_migrations` table exists in the target database.
3. Apply each SQL migration once, tracked by filename and checksum.

From the `crm_postgresql_db/` directory:
- `./startup.sh` (starts PostgreSQL if needed and runs migrations)
- Or directly run `./run_migrations.sh` if PostgreSQL is already running.

Connection info is saved to:
- `crm_postgresql_db/db_connection.txt`
- `crm_postgresql_db/db_visualizer/postgres.env`

### Fallback (if extensions are not allowed)

If your environment does not permit `CREATE EXTENSION` (e.g., restricted managed Postgres), you will need to replace CITEXT with TEXT and enforce case-insensitive uniqueness using functional indexes. The general approach:

1. In `0001_init.sql`:
   - Replace `CITEXT` column types (e.g., `users.email`, `customers.email`) with `TEXT`.

2. In `0002_constraints_indexes.sql`:
   - Replace unique indexes on those email columns with functional unique indexes:
     - `CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_ci ON users (lower(email));`
     - `CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_email_ci ON customers (lower(email));`

3. If you have existing constraints that depend on the unique email, ensure these functional indexes are the ones referenced for uniqueness.

Prefer the extension path when possible for simplicity and correctness.

### PostgreSQL 16 Compatibility

Migrations have been updated to enable required extensions first and are idempotent. With the new `0000_enable_extensions.sql`, migrations succeed without error on PostgreSQL 16.

```text
- 0000_enable_extensions.sql  -> enables citext (idempotent)
- 0001_init.sql               -> creates tables using CITEXT where needed
- 0002_constraints_indexes.sql-> adds indexes/constraints
- 0003_triggers.sql           -> adds triggers and audit logic
- 0004_seed.sql               -> seeds initial data
```

If your environment blocks extensions, follow the fallback steps above.
