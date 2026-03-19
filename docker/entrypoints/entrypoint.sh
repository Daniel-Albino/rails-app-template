#!/usr/bin/env bash
# =============================================================================
# docker/entrypoints/entrypoint.sh
# Main Rails container entrypoint.
# Runs every time the container starts.
# =============================================================================

set -e  # Exit immediately on command failure

# Colored output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

APP_HOME=${APP_HOME:-/app}
SETUP_FILE="${APP_HOME}/setupcomplete"

# =============================================================================
# STEP 1 - Install system dependencies (if needed)
# =============================================================================
if [ -f /usr/local/bin/install-system-dependencies.sh ]; then
  log_info "Checking system dependencies..."
  /usr/local/bin/install-system-dependencies.sh
fi

# =============================================================================
# STEP 2 - Bundle install
# Ensure all gems are installed/updated.
# =============================================================================
log_info "Checking gems (bundle install)..."
cd "${APP_HOME}"

bundle check || bundle install --jobs="${BUNDLE_JOBS:-4}" --retry="${BUNDLE_RETRY:-3}"
log_success "Gems ready."

# =============================================================================
# STEP 3 - Yarn install (if package.json exists)
# =============================================================================
if [ -f "${APP_HOME}/package.json" ]; then
  log_info "Checking Node dependencies (yarn install)..."
  yarn install --check-files 2>/dev/null || yarn install
  log_success "Node modules ready."
fi

# =============================================================================
# STEP 4 - Remove stale server.pid (prevents restart crash)
# =============================================================================
PID_FILE="${APP_HOME}/tmp/pids/server.pid"
if [ -f "${PID_FILE}" ]; then
  log_warning "server.pid file found. Removing..."
  rm -f "${PID_FILE}"
  log_success "server.pid removed."
fi

# =============================================================================
# STEP 5 - Initial database setup
# Run rails db:prepare only on first boot (when setupcomplete does not exist).
# On later boots, only run pending migrations.
# =============================================================================

# Wait for PostgreSQL using pg_isready (fast, no Rails boot needed)
wait_for_db() {
  local host="${POSTGRES_HOST:-db}"
  local port="${POSTGRES_PORT:-5432}"
  local user="${POSTGRES_USER:-postgres}"

  log_info "Waiting for PostgreSQL at ${host}:${port}..."
  until pg_isready -h "${host}" -p "${port}" -U "${user}" -q; do
    sleep 1
  done
  log_success "Database available."
}

if [ "${RAILS_ENV}" != "test" ] && [ "${SKIP_DB_PREPARE:-false}" != "true" ]; then
  wait_for_db

  if [ ! -f "${SETUP_FILE}" ]; then
    log_info "First run detected. Preparing database..."

    # db:prepare creates DB if missing, or runs migrations if schema exists
    bundle exec rails db:prepare --trace

    touch "${SETUP_FILE}"
    log_success "Database prepared. 'setupcomplete' created."
  else
    log_info "Previous setup detected. Running pending migrations only..."
    bundle exec rails db:migrate 2>/dev/null || log_warning "No migration changes or non-critical migration issue."
    log_success "Migrations checked."
  fi
fi

# =============================================================================
# STEP 6 - Run the container command
# Example: "bundle exec rails server -b 0.0.0.0 -p 3000"
# =============================================================================
log_success "Container ready. Starting: $*"
echo ""
exec "$@"
