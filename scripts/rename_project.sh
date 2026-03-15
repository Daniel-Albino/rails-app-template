#!/usr/bin/env bash
# =============================================================================
# scripts/rename_project.sh
# Script para renomear o projecto de "my_app" para um novo nome.
#
# Uso:
#   bash scripts/rename_project.sh novo_nome_do_projecto
#
# Exemplo:
#   bash scripts/rename_project.sh awesome_saas
#
# O script irá:
#   1. Validar o novo nome
#   2. Substituir todas as ocorrências nos ficheiros de configuração
#   3. Renomear ficheiros e directórios relevantes
#   4. Actualizar referências nos ficheiros Ruby/YAML/JSON/Shell
# =============================================================================

set -e

# ---------------------------------------------------------------------------
# Cores
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
log_step()    { echo -e "\n${CYAN}${BOLD}▶ $1${NC}"; }

# ---------------------------------------------------------------------------
# Validação de argumentos
# ---------------------------------------------------------------------------
if [ -z "$1" ]; then
  log_error "Uso: bash scripts/rename_project.sh <novo_nome>\nExemplo: bash scripts/rename_project.sh awesome_saas"
fi

NEW_NAME="$1"
OLD_NAME="my_app"

# Valida formato do nome: apenas letras minúsculas, números e underscores
if [[ ! "${NEW_NAME}" =~ ^[a-z][a-z0-9_]*$ ]]; then
  log_error "Nome inválido: '${NEW_NAME}'\nDevem usar apenas letras minúsculas, números e underscores. Deve começar com letra."
fi

if [ "${NEW_NAME}" = "${OLD_NAME}" ]; then
  log_warning "O novo nome é igual ao actual ('${OLD_NAME}'). Nada a fazer."
  exit 0
fi

# ---------------------------------------------------------------------------
# Derivar variantes do nome (snake_case → CamelCase, etc.)
# ---------------------------------------------------------------------------
# snake_case → CamelCase (my_awesome_app → MyAwesomeApp)
# Nota: o OLD_CAMEL é sempre "MyApp" (nome fixo do template).
#       O NEW_CAMEL é derivado do novo nome fornecido.
to_camel_case() {
  echo "$1" | sed 's/_\([a-z]\)/\U\1/g;s/^\([a-z]\)/\U\1/'
}

# O nome antigo do template é SEMPRE MyApp / my_app
OLD_CAMEL="MyApp"
NEW_CAMEL=$(to_camel_case "${NEW_NAME}")

# Se o novo nome não tem underscores (ex: myapp), to_camel_case apenas
# capitaliza a primeira letra (Myapp). Para nomes sem underscore isso é
# o comportamento correcto em Ruby (module Myapp é válido).
# Se quiseres um CamelCase diferente, edita NEW_CAMEL manualmente aqui.

# human readable (my_app → My App)
OLD_HUMAN=$(echo "${OLD_NAME}" | sed 's/_/ /g;s/\b\(.\)/\u\1/g')
NEW_HUMAN=$(echo "${NEW_NAME}" | sed 's/_/ /g;s/\b\(.\)/\u\1/g')

echo ""
echo -e "${BOLD}============================================================${NC}"
echo -e "${BOLD}  Rename: ${RED}${OLD_NAME}${NC} → ${GREEN}${NEW_NAME}${BOLD}${NC}"
echo -e "${BOLD}============================================================${NC}"
echo ""
echo -e "  snake_case : ${RED}${OLD_NAME}${NC} → ${GREEN}${NEW_NAME}${NC}"
echo -e "  CamelCase  : ${RED}${OLD_CAMEL}${NC} → ${GREEN}${NEW_CAMEL}${NC}"
echo -e "  Human      : ${RED}${OLD_HUMAN}${NC} → ${GREEN}${NEW_HUMAN}${NC}"
echo ""

read -p "$(echo -e "${YELLOW}Confirmas? (s/N):${NC} ")" CONFIRM
if [[ ! "${CONFIRM}" =~ ^[sS]$ ]]; then
  log_warning "Operação cancelada."
  exit 0
fi

# ---------------------------------------------------------------------------
# Ficheiros a processar (substituição de texto)
# ---------------------------------------------------------------------------
log_step "PASSO 1 — A substituir referências nos ficheiros..."

FILES_TO_PROCESS=(
  # Docker
  "Dockerfile"
  "docker-compose.yml"
  "docker-compose.prod.yml"
  ".env.example"
  ".env"
  ".dockerignore"
  # Ruby/Rails
  "Gemfile"
  "Gemfile.lock"
  "Rakefile"
  "config.ru"
  "Procfile.dev"
  # Config
  "config/application.rb"
  "config/environment.rb"
  "config/routes.rb"
  "config/database.yml"
  "config/cable.yml"
  "config/puma.rb"
  "config/sidekiq.yml"
  "config/storage.yml"
  "config/importmap.rb"
  "config/environments/development.rb"
  "config/environments/production.rb"
  "config/environments/test.rb"
  "config/initializers/sidekiq.rb"
  "config/initializers/filter_parameter_logging.rb"
  "config/initializers/content_security_policy.rb"
  "config/initializers/inflections.rb"
  "config/locales/pt.yml"
  "config/locales/en.yml"
  # Node
  "package.json"
  "yarn.lock"
  # Docker scripts e envs
  "docker/environments/development.env"
  "docker/environments/production.env"
  "docker/entrypoints/entrypoint.sh"
  "docker/scripts/install-system-dependencies.sh"
  "docker/scripts/wait-for-db.sh"
  "docker/scripts/ci-test.sh"
  "docker/scripts/deploy.sh"
  "docker/nginx/nginx.conf"
  "docker/nginx/conf.d/my_app.conf"
  # CI/CD
  ".github/workflows/ci.yml"
  # Views / Helpers
  "app/helpers/application_helper.rb"
  "app/mailers/application_mailer.rb"
  "app/views/layouts/application.html.erb"
  "app/views/layouts/mailer.html.erb"
  "app/views/layouts/mailer.text.erb"
  "app/views/shared/_flash.html.erb"
  # Seeds
  "db/seeds.rb"
  # Docs
  "README.md"
)

for file in "${FILES_TO_PROCESS[@]}"; do
  if [ -f "${file}" ]; then
    # Substitui snake_case
    sed -i "s/${OLD_NAME}/${NEW_NAME}/g" "${file}"
    # Substitui CamelCase
    sed -i "s/${OLD_CAMEL}/${NEW_CAMEL}/g" "${file}"
    log_success "Actualizado: ${file}"
  else
    log_warning "Não encontrado (ignorado): ${file}"
  fi
done

# Processa recursivamente a pasta app/ para módulos Rails
log_step "PASSO 2 — A actualizar módulos Ruby (app/, config/initializers/)..."

find app/ config/initializers/ lib/ -name "*.rb" 2>/dev/null | while read -r file; do
  if grep -q "${OLD_CAMEL}\|${OLD_NAME}" "${file}" 2>/dev/null; then
    sed -i "s/${OLD_CAMEL}/${NEW_CAMEL}/g" "${file}"
    sed -i "s/${OLD_NAME}/${NEW_NAME}/g" "${file}"
    log_success "Actualizado: ${file}"
  fi
done

# ---------------------------------------------------------------------------
# Renomeia ficheiros e directórios relevantes
# ---------------------------------------------------------------------------
log_step "PASSO 3 — A renomear ficheiros com o nome do projecto..."

# Renomeia o ficheiro de configuração Nginx
if [ -f "docker/nginx/conf.d/${OLD_NAME}.conf" ]; then
  mv "docker/nginx/conf.d/${OLD_NAME}.conf" "docker/nginx/conf.d/${NEW_NAME}.conf"
  log_success "Renomeado: docker/nginx/conf.d/${OLD_NAME}.conf → ${NEW_NAME}.conf"
fi

# Pasta tmp/storage com nome do projecto (raro mas possível)
if [ -d "tmp/${OLD_NAME}" ]; then
  mv "tmp/${OLD_NAME}" "tmp/${NEW_NAME}"
  log_success "Renomeado: tmp/${OLD_NAME} → tmp/${NEW_NAME}"
fi

# ---------------------------------------------------------------------------
# Limpa ficheiros de setup para forçar novo setup
# ---------------------------------------------------------------------------
log_step "PASSO 4 — A limpar ficheiros de setup anteriores..."

if [ -f "setupcomplete" ]; then
  rm -f "setupcomplete"
  log_success "Ficheiro 'setupcomplete' removido (novo setup será executado)."
fi

# ---------------------------------------------------------------------------
# Copia .env.example para .env se .env não existir
# ---------------------------------------------------------------------------
log_step "PASSO 5 — A verificar ficheiro .env..."

if [ ! -f ".env" ]; then
  cp .env.example .env
  log_success "Criado .env a partir de .env.example"
  log_warning "Edita o ficheiro .env com as tuas credenciais reais!"
else
  log_warning ".env já existe. A substituir referências ao nome antigo..."
  sed -i "s/${OLD_NAME}/${NEW_NAME}/g" ".env"
  sed -i "s/${OLD_CAMEL}/${NEW_CAMEL}/g" ".env"
fi

# ---------------------------------------------------------------------------
# Cria/actualiza README com novo nome
# ---------------------------------------------------------------------------
log_step "PASSO 6 — A actualizar README.md..."

if [ -f "README.md" ]; then
  sed -i "s/${OLD_NAME}/${NEW_NAME}/g" README.md
  sed -i "s/${OLD_CAMEL}/${NEW_CAMEL}/g" README.md
  sed -i "s/${OLD_HUMAN}/${NEW_HUMAN}/g" README.md
  log_success "README.md actualizado."
fi

# ---------------------------------------------------------------------------
# Resumo final
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}============================================================${NC}"
echo -e "${GREEN}${BOLD}  ✅ Projecto renomeado com sucesso!${NC}"
echo -e "${BOLD}============================================================${NC}"
echo ""
echo -e "  Nome anterior : ${RED}${OLD_NAME}${NC}"
echo -e "  Nome novo     : ${GREEN}${NEW_NAME}${NC}"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo -e "  1. Verifica o ficheiro ${CYAN}.env${NC} com as tuas credenciais"
echo -e "  2. Executa: ${CYAN}docker compose down -v${NC} (limpa volumes antigos)"
echo -e "  3. Executa: ${CYAN}docker compose up --build${NC}"
echo ""
