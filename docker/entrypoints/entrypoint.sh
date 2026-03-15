#!/usr/bin/env bash
# =============================================================================
# docker/entrypoints/entrypoint.sh
# Entrypoint principal do container Rails.
# Executado sempre que o container inicia.
# =============================================================================

set -e  # Termina imediatamente se algum comando falhar

# Cores para output legível
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
# PASSO 1 — Instalar dependências de sistema (se necessário)
# =============================================================================
if [ -f /usr/local/bin/install-system-dependencies.sh ]; then
  log_info "A verificar dependências de sistema..."
  /usr/local/bin/install-system-dependencies.sh
fi

# =============================================================================
# PASSO 2 — Bundle Install
# Garante que todas as gems estão instaladas/actualizadas.
# =============================================================================
log_info "A verificar gems (bundle install)..."
cd "${APP_HOME}"

bundle check || bundle install --jobs="${BUNDLE_JOBS:-4}" --retry="${BUNDLE_RETRY:-3}"
log_success "Gems prontas."

# =============================================================================
# PASSO 3 — Yarn Install (se package.json existir)
# =============================================================================
if [ -f "${APP_HOME}/package.json" ]; then
  log_info "A verificar dependências Node (yarn install)..."
  yarn install --check-files 2>/dev/null || yarn install
  log_success "Node modules prontos."
fi

# =============================================================================
# PASSO 4 — Remover server.pid antigo (evita crash ao reiniciar)
# =============================================================================
PID_FILE="${APP_HOME}/tmp/pids/server.pid"
if [ -f "${PID_FILE}" ]; then
  log_warning "Ficheiro server.pid encontrado. A remover..."
  rm -f "${PID_FILE}"
  log_success "server.pid removido."
fi

# =============================================================================
# PASSO 5 — Setup inicial da base de dados
# Executa rails db:prepare apenas na PRIMEIRA vez (quando setupcomplete não existe).
# Nas execuções seguintes, corre apenas as migrations pendentes.
# =============================================================================

# Aguarda PostgreSQL estar disponível usando pg_isready (rápido, sem carregar Rails)
wait_for_db() {
  local host="${POSTGRES_HOST:-db}"
  local port="${POSTGRES_PORT:-5432}"
  local user="${POSTGRES_USER:-postgres}"

  log_info "A aguardar PostgreSQL em ${host}:${port}..."
  until pg_isready -h "${host}" -p "${port}" -U "${user}" -q; do
    sleep 1
  done
  log_success "Base de dados disponível."
}

if [ "${RAILS_ENV}" != "test" ]; then
  wait_for_db

  if [ ! -f "${SETUP_FILE}" ]; then
    log_info "Primeira execução detectada. A preparar base de dados..."

    # db:prepare cria a DB se não existir, ou corre migrations se já existir schema
    bundle exec rails db:prepare --trace

    touch "${SETUP_FILE}"
    log_success "Base de dados preparada. Ficheiro 'setupcomplete' criado."
  else
    log_info "Setup anterior detectado. A correr apenas migrations pendentes..."
    bundle exec rails db:migrate 2>/dev/null || log_warning "Migrations sem alterações ou com erro não crítico."
    log_success "Migrations verificadas."
  fi
fi

# =============================================================================
# PASSO 6 — Executar o comando passado ao container
# Exemplo: "bundle exec rails server -b 0.0.0.0 -p 3000"
# =============================================================================
log_success "Container pronto. A iniciar: $*"
echo ""
exec "$@"
