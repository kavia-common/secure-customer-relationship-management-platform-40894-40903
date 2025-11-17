#!/bin/bash
# Simple Postgres migrations runner with checksum tracking and idempotency.
# Applies all SQL files in ./migrations in lexicographic order and records them in app_migrations.

set -euo pipefail

DB_NAME="myapp"
DB_USER="appuser"
DB_PASSWORD="dbuser123"
DB_PORT="5000"

echo "[migrate] Starting migrations for database '${DB_NAME}' on port ${DB_PORT}"

# Locate postgres binaries
PG_VERSION=$(ls /usr/lib/postgresql/ 2>/dev/null | head -1)
if [ -z "${PG_VERSION}" ]; then
  echo "[migrate] ERROR: PostgreSQL binaries not found under /usr/lib/postgresql"
  exit 1
fi
PG_BIN="/usr/lib/postgresql/${PG_VERSION}/bin"

# Ensure migrations table exists
echo "[migrate] Ensuring migrations table exists..."
sudo -u postgres ${PG_BIN}/psql -v ON_ERROR_STOP=1 -p ${DB_PORT} -d ${DB_NAME} -c "
CREATE TABLE IF NOT EXISTS app_migrations (
  filename    TEXT PRIMARY KEY,
  checksum    TEXT NOT NULL,
  applied_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
"

# Nothing to do if no migrations directory
MIGRATIONS_DIR="$(cd "$(dirname "$0")" && pwd)/migrations"
if [ ! -d "${MIGRATIONS_DIR}" ]; then
  echo "[migrate] No migrations directory at ${MIGRATIONS_DIR}; skipping."
  exit 0
fi

shopt -s nullglob
MIG_FILES=("${MIGRATIONS_DIR}"/*.sql)
shopt -u nullglob

if [ ${#MIG_FILES[@]} -eq 0 ]; then
  echo "[migrate] No migration SQL files found; nothing to apply."
  exit 0
fi

# Apply each migration in order
for file in $(printf "%s\n" "${MIG_FILES[@]}" | sort); do
  base=$(basename "${file}")
  checksum=$(md5sum "${file}" | awk '{print $1}')

  echo "[migrate] Considering ${base} (checksum ${checksum})..."

  # Check if this file has already been applied
  already=$(
    sudo -u postgres ${PG_BIN}/psql -A -t -p ${DB_PORT} -d ${DB_NAME} -v ON_ERROR_STOP=1 \
      -c "SELECT checksum FROM app_migrations WHERE filename='${base}'"
  )
  already=$(echo "${already}" | tr -d '[:space:]')

  if [ -n "${already}" ]; then
    if [ "${already}" = "${checksum}" ]; then
      echo "[migrate] Skipping ${base} (already applied with same checksum)"
      continue
    else
      echo "[migrate] WARNING: ${base} was previously applied with a different checksum (${already})."
      echo "[migrate]          Skipping re-apply to protect data integrity. Create a new migration file instead."
      continue
    fi
  fi

  echo "[migrate] Applying ${base} ..."
  # Apply with ON_ERROR_STOP to stop at first failure
  sudo -u postgres ${PG_BIN}/psql -v ON_ERROR_STOP=1 -p ${DB_PORT} -d ${DB_NAME} -f "${file}"

  # Record successful application
  sudo -u postgres ${PG_BIN}/psql -v ON_ERROR_STOP=1 -p ${DB_PORT} -d ${DB_NAME} -c \
    "INSERT INTO app_migrations (filename, checksum) VALUES ('${base}', '${checksum}');"

  echo "[migrate] Applied ${base} successfully."
done

echo "[migrate] All migrations processed."
