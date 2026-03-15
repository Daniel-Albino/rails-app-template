#!/usr/bin/env bash
# =============================================================================
# docker/scripts/ci-test.sh
# Script para correr a suite de testes em CI/CD (GitHub Actions, GitLab CI, etc.)
#
# Uso (via docker compose):
#   docker compose run --rm -e RAILS_ENV=test web bash docker/scripts/ci-test.sh
# =============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[CI]${NC} $1"; }
ok()  { echo -e "${GREEN}[CI]${NC} $1"; }
err() { echo -e "${RED}[CI]${NC} $1"; exit 1; }

export RAILS_ENV=test

log "== Iniciando suite de testes CI =="

# Aguarda DB
log "A aguardar base de dados..."
bash docker/scripts/wait-for-db.sh

# Instala gems
log "A verificar gems..."
bundle check || bundle install --jobs=4 --retry=3

# Prepara base de dados de teste
log "A preparar base de dados de teste..."
bundle exec rails db:prepare

# Linting com RuboCop
log "A correr RuboCop..."
bundle exec rubocop --no-color --format progress || err "RuboCop falhou."
ok "RuboCop passou."

# Análise de segurança com Brakeman
log "A correr Brakeman..."
bundle exec brakeman --no-progress --quiet || err "Brakeman encontrou vulnerabilidades."
ok "Brakeman passou."

# Suite de testes RSpec
log "A correr RSpec..."
bundle exec rspec --format progress --format json --out tmp/rspec_results.json
ok "RSpec passou."

log "== Todos os checks passaram com sucesso! =="
