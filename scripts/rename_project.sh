#!/usr/bin/env bash
# =============================================================================
# scripts/rename_project.sh
# Rename template project from "my_app" to a new name.
#
# Usage:
#   bash scripts/rename_project.sh new_project_name
#   bash scripts/rename_project.sh new_project_name --yes
#   bash scripts/rename_project.sh new_project_name --dry-run
#
# Example:
#   bash scripts/rename_project.sh awesome_saas
#
# This script will:
#   1. Validate the new name
#   2. Replace name references across text files
#   3. Rename relevant files/directories
#   4. Refresh .env from .env.example when missing
# =============================================================================

set -e

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
log_step()    { echo -e "\n${CYAN}${BOLD}>> $1${NC}"; }

if [ -z "$1" ]; then
  log_error "Usage: bash scripts/rename_project.sh <new_name>\nExample: bash scripts/rename_project.sh awesome_saas"
fi

NEW_NAME="$1"
OLD_NAME="my_app"
AUTO_CONFIRM=false
DRY_RUN=false

for arg in "$@"; do
  case "${arg}" in
    --yes|-y) AUTO_CONFIRM=true ;;
    --dry-run) DRY_RUN=true ;;
  esac
done

# Validate format: lowercase letters, numbers, underscores
if [[ ! "${NEW_NAME}" =~ ^[a-z][a-z0-9_]*$ ]]; then
  log_error "Invalid name: '${NEW_NAME}'\nUse lowercase letters, numbers, and underscores only. Must start with a letter."
fi

if [ "${NEW_NAME}" = "${OLD_NAME}" ]; then
  log_warning "New name is the same as current name ('${OLD_NAME}'). Nothing to do."
  exit 0
fi

# snake_case -> CamelCase (my_awesome_app -> MyAwesomeApp)
to_camel_case() {
  echo "$1" | sed 's/_\([a-z]\)/\U\1/g;s/^\([a-z]\)/\U\1/'
}

OLD_CAMEL="MyApp"
NEW_CAMEL=$(to_camel_case "${NEW_NAME}")

# Human-readable label (my_app -> My App)
OLD_HUMAN=$(echo "${OLD_NAME}" | sed 's/_/ /g;s/\b\(.\)/\u\1/g')
NEW_HUMAN=$(echo "${NEW_NAME}" | sed 's/_/ /g;s/\b\(.\)/\u\1/g')

echo ""
echo -e "${BOLD}============================================================${NC}"
echo -e "${BOLD}  Rename: ${RED}${OLD_NAME}${NC} -> ${GREEN}${NEW_NAME}${BOLD}${NC}"
echo -e "${BOLD}============================================================${NC}"
echo ""
echo -e "  snake_case : ${RED}${OLD_NAME}${NC} -> ${GREEN}${NEW_NAME}${NC}"
echo -e "  CamelCase  : ${RED}${OLD_CAMEL}${NC} -> ${GREEN}${NEW_CAMEL}${NC}"
echo -e "  Human      : ${RED}${OLD_HUMAN}${NC} -> ${GREEN}${NEW_HUMAN}${NC}"
echo ""
if [ "${AUTO_CONFIRM}" = false ]; then
  read -p "$(echo -e "${YELLOW}Continue? (y/N):${NC} ")" CONFIRM
  if [[ ! "${CONFIRM}" =~ ^[yY]$ ]]; then
    log_warning "Operation cancelled."
    exit 0
  fi
fi

replace_in_file() {
  local file="$1"
  if [ "${DRY_RUN}" = true ]; then
    log_info "[DRY-RUN] Would update: ${file}"
    return
  fi

  perl -0pi -e "s/\Q${OLD_NAME}\E/${NEW_NAME}/g; s/\Q${OLD_CAMEL}\E/${NEW_CAMEL}/g; s/\Q${OLD_HUMAN}\E/${NEW_HUMAN}/g;" "${file}"
  log_success "Updated: ${file}"
}

log_step "STEP 1 - Replacing references in text files..."

FILES_TO_PROCESS=(
  "Dockerfile"
  "docker-compose.yml"
  "docker-compose.prod.yml"
  ".env.example"
  ".env"
  ".dockerignore"
  "Gemfile"
  "Gemfile.lock"
  "Rakefile"
  "config.ru"
  "Procfile.dev"
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
  "config/locales/en.yml"
  "package.json"
  "yarn.lock"
  "bin/setup"
  "bin/docker-entrypoint"
  "lib/tasks/db.rake"
  "lib/tasks/docker.rake"
  "docker/environments/development.env"
  "docker/environments/production.env"
  "docker/entrypoints/entrypoint.sh"
  "docker/scripts/install-system-dependencies.sh"
  "docker/scripts/wait-for-db.sh"
  "docker/scripts/ci-test.sh"
  "docker/scripts/deploy.sh"
  "docker/nginx/nginx.conf"
  "docker/nginx/conf.d/my_app.conf"
  ".github/workflows/ci.yml"
  "app/helpers/application_helper.rb"
  "app/mailers/application_mailer.rb"
  "app/views/layouts/application.html.erb"
  "app/views/layouts/mailer.html.erb"
  "app/views/layouts/mailer.text.erb"
  "app/views/shared/_flash.html.erb"
  "db/seeds.rb"
  "README.md"
)

for file in "${FILES_TO_PROCESS[@]}"; do
  if [ -f "${file}" ]; then
    replace_in_file "${file}"
  else
    log_warning "Not found (skipped): ${file}"
  fi
done

log_step "STEP 2 - Applying recursive replacements in common source files..."
while IFS= read -r file; do
  case "${file}" in
    node_modules/*|vendor/*|tmp/*|log/*|storage/*|.git/*) continue ;;
  esac
  replace_in_file "${file}"
done < <(rg --files \
  -g "*.rb" -g "*.yml" -g "*.yaml" -g "*.md" -g "*.sh" -g "*.json" -g "*.erb" -g "*.env" \
  -g "!node_modules/**" -g "!vendor/**" -g "!tmp/**" -g "!log/**" -g "!storage/**" -g "!.git/**")

log_step "STEP 3 - Renaming project-specific files..."
if [ -f "docker/nginx/conf.d/${OLD_NAME}.conf" ]; then
  if [ "${DRY_RUN}" = true ]; then
    log_info "[DRY-RUN] Would rename docker/nginx/conf.d/${OLD_NAME}.conf -> ${NEW_NAME}.conf"
  else
    mv "docker/nginx/conf.d/${OLD_NAME}.conf" "docker/nginx/conf.d/${NEW_NAME}.conf"
    log_success "Renamed: docker/nginx/conf.d/${OLD_NAME}.conf -> ${NEW_NAME}.conf"
  fi
fi

if [ -d "tmp/${OLD_NAME}" ]; then
  if [ "${DRY_RUN}" = true ]; then
    log_info "[DRY-RUN] Would rename tmp/${OLD_NAME} -> tmp/${NEW_NAME}"
  else
    mv "tmp/${OLD_NAME}" "tmp/${NEW_NAME}"
    log_success "Renamed: tmp/${OLD_NAME} -> tmp/${NEW_NAME}"
  fi
fi

log_step "STEP 4 - Cleaning setup markers..."

if [ -f "setupcomplete" ]; then
  if [ "${DRY_RUN}" = true ]; then
    log_info "[DRY-RUN] Would remove setupcomplete"
  else
    rm -f "setupcomplete"
    log_success "Removed 'setupcomplete' (setup will run on next boot)."
  fi
fi

log_step "STEP 5 - Validating .env..."

if [ ! -f ".env" ]; then
  if [ "${DRY_RUN}" = true ]; then
    log_info "[DRY-RUN] Would create .env from .env.example"
  else
    cp .env.example .env
    log_success "Created .env from .env.example"
    log_warning "Update .env with real credentials."
  fi
else
  log_warning ".env already exists. Updating app-name references..."
  replace_in_file ".env"
fi

echo ""
echo -e "${BOLD}============================================================${NC}"
if [ "${DRY_RUN}" = true ]; then
  echo -e "${GREEN}${BOLD}  Dry-run completed successfully!${NC}"
else
  echo -e "${GREEN}${BOLD}  Project renamed successfully!${NC}"
fi
echo -e "${BOLD}============================================================${NC}"
echo ""
echo -e "  Previous name : ${RED}${OLD_NAME}${NC}"
echo -e "  New name      : ${GREEN}${NEW_NAME}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Check ${CYAN}.env${NC} and set real credentials"
echo -e "  2. Run: ${CYAN}docker compose down -v${NC} (clear old volumes)"
echo -e "  3. Run: ${CYAN}docker compose up --build${NC}"
echo ""
