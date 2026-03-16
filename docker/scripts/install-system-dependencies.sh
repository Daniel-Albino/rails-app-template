#!/usr/bin/env bash
# =============================================================================
# docker/scripts/install-system-dependencies.sh
# Install system dependencies required by the Rails project.
# Executed from entrypoint - uses cache to avoid reinstalling.
# =============================================================================

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[DEPS]${NC} $1"; }
log_success() { echo -e "${GREEN}[DEPS]${NC} $1"; }
log_skip()    { echo -e "${YELLOW}[DEPS]${NC} $1"; }

DEPS_STAMP="/tmp/.system-deps-installed"

if [ -f "${DEPS_STAMP}" ]; then
  log_skip "System dependencies already installed. Skipping."
  exit 0
fi

log_info "Installing system dependencies..."

apt-get update -qq

# Build and compilation
apt-get install -y --no-install-recommends \
  build-essential \
  gcc \
  g++ \
  make \
  pkg-config \
  autoconf \
  automake

# System and runtime
apt-get install -y --no-install-recommends \
  curl \
  wget \
  gnupg2 \
  ca-certificates \
  git \
  less \
  vim

# PostgreSQL
apt-get install -y --no-install-recommends \
  libpq-dev \
  postgresql-client

# SSL and network
apt-get install -y --no-install-recommends \
  libssl-dev \
  libffi-dev \
  libyaml-dev

# XML/HTML (Nokogiri)
apt-get install -y --no-install-recommends \
  libxml2-dev \
  libxslt1-dev

# Images (ActiveStorage + image_processing)
apt-get install -y --no-install-recommends \
  libvips42 \
  imagemagick \
  libjpeg-dev \
  libpng-dev \
  libwebp-dev

# Node.js 20 LTS
if ! command -v node &> /dev/null; then
  log_info "Installing Node.js 20 LTS..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y --no-install-recommends nodejs
  log_success "Node.js $(node --version) installed."
else
  log_skip "Node.js already installed: $(node --version)"
fi

# Yarn
if ! command -v yarn &> /dev/null; then
  log_info "Installing Yarn..."
  npm install -g yarn
  log_success "Yarn $(yarn --version) installed."
else
  log_skip "Yarn already installed: $(yarn --version)"
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

touch "${DEPS_STAMP}"
log_success "System dependencies installed successfully."
