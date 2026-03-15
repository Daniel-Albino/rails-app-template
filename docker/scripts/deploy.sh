#!/usr/bin/env bash
# =============================================================================
# docker/scripts/deploy.sh
# Script de deploy para produção via Docker Compose.
#
# Uso:
#   bash docker/scripts/deploy.sh
#   bash docker/scripts/deploy.sh --skip-backup
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${BLUE}[DEPLOY]${NC} $1"; }
ok()   { echo -e "${GREEN}[DEPLOY]${NC} $1"; }
warn() { echo -e "${YELLOW}[DEPLOY]${NC} $1"; }
err()  { echo -e "${RED}[DEPLOY]${NC} $1"; exit 1; }

COMPOSE_FILES="-f docker-compose.yml -f docker-compose.prod.yml"
SKIP_BACKUP=false

# Parse argumentos
for arg in "$@"; do
  case $arg in
    --skip-backup) SKIP_BACKUP=true ;;
  esac
done

echo ""
echo -e "${BOLD}============================================================${NC}"
echo -e "${BOLD}  Deploy my_app → Produção${NC}"
echo -e "${BOLD}============================================================${NC}"
echo ""

# Verifica que .env existe
[ -f ".env" ] || err "Ficheiro .env não encontrado. Cria-o a partir de .env.example."

# Verifica variáveis obrigatórias
[ -z "$SECRET_KEY_BASE" ] && err "SECRET_KEY_BASE não definido no .env"
[ -z "$POSTGRES_PASSWORD" ] && err "POSTGRES_PASSWORD não definido no .env"

# Passo 1: Backup da base de dados
if [ "$SKIP_BACKUP" = false ]; then
  log "PASSO 1/6 — Backup da base de dados..."
  BACKUP_FILE="tmp/db_backup_$(date +%Y%m%d_%H%M%S).sql"
  docker compose $COMPOSE_FILES exec -T db \
    pg_dump -U "${POSTGRES_USER:-postgres}" "${POSTGRES_DB:-my_app_production}" \
    > "$BACKUP_FILE" 2>/dev/null || warn "Backup falhou (pode ser o primeiro deploy)"
  ok "Backup guardado em: $BACKUP_FILE"
else
  warn "PASSO 1/6 — Backup ignorado (--skip-backup)"
fi

# Passo 2: Pull da imagem base mais recente
log "PASSO 2/6 — A actualizar imagens base..."
docker compose $COMPOSE_FILES pull db redis 2>/dev/null || true
ok "Imagens base actualizadas."

# Passo 3: Build da nova imagem
log "PASSO 3/6 — A construir imagem de produção..."
docker compose $COMPOSE_FILES build --no-cache web
ok "Imagem construída."

# Passo 4: Correr migrations
log "PASSO 4/6 — A correr migrations..."
docker compose $COMPOSE_FILES run --rm web bundle exec rails db:migrate
ok "Migrations aplicadas."

# Passo 5: Reiniciar serviços com zero downtime
log "PASSO 5/6 — A reiniciar serviços..."
docker compose $COMPOSE_FILES up -d --no-deps web nginx
ok "Serviços reiniciados."

# Passo 6: Health check
log "PASSO 6/6 — A verificar health..."
sleep 5
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
  ok "Health check passou (HTTP $HTTP_STATUS)."
else
  err "Health check falhou (HTTP $HTTP_STATUS). Verifica os logs: docker compose logs web"
fi

echo ""
echo -e "${GREEN}${BOLD}  Deploy concluído com sucesso!${NC}"
echo ""
docker compose $COMPOSE_FILES ps
echo ""
