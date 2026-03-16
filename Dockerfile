# =============================================================================
# STAGE 1: base
# Base image shared by development and production.
# Installs system dependencies and configures Ruby environment.
# =============================================================================
FROM ruby:3.3.6-slim AS base

# Build arguments
ARG APP_USER=rails
ARG APP_HOME=/app

# Base environment variables
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    GEM_HOME=/usr/local/bundle \
    PATH="/usr/local/bundle/bin:$PATH" \
    APP_HOME=${APP_HOME}

WORKDIR ${APP_HOME}

# Install minimal base system dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      curl \
      gnupg2 \
      ca-certificates \
      libpq5 && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# STAGE 2: dependencies
# Install all build dependencies (gems + node_modules).
# Kept separate to maximize Docker cache reuse.
# =============================================================================
FROM base AS dependencies

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      libssl-dev \
      libxml2-dev \
      libxslt1-dev \
      git \
      pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS + Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists/*

# Copy dependency files first for better caching
COPY Gemfile Gemfile.lock* ./

# Install gems (cached if Gemfile does not change)
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}/ruby/*/cache" \
           "${BUNDLE_PATH}/ruby/*/bundler/gems/*/.git"

# Copy package.json and install Node dependencies
COPY package.json yarn.lock* ./
RUN yarn install --no-frozen-lockfile

# =============================================================================
# STAGE 3: development
# Development image with hot reload and debugging tools.
# =============================================================================
FROM dependencies AS development

ENV RAILS_ENV=development \
    NODE_ENV=development \
    RAILS_LOG_TO_STDOUT=true

# Install extra dev tools (useful but not required in production)
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      vim \
      less \
      postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Copy entrypoint and scripts
COPY docker/entrypoints/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/scripts/install-system-dependencies.sh /usr/local/bin/install-system-dependencies.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
             /usr/local/bin/install-system-dependencies.sh

# Copy application source code
COPY . .

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

# =============================================================================
# STAGE 4: assets (production - precompile assets)
# =============================================================================
FROM dependencies AS assets

ENV RAILS_ENV=production \
    NODE_ENV=production \
    RAILS_LOG_TO_STDOUT=true

COPY . .

RUN bundle exec rails secret > /tmp/secret && \
    SECRET_KEY_BASE=$(cat /tmp/secret) \
    ASSETS_PRECOMPILE=1 \
    bundle exec rails assets:precompile && \
    rm /tmp/secret

# =============================================================================
# STAGE 5: production
# Final production image - minimal, secure, optimized.
# =============================================================================
FROM base AS production

ENV RAILS_ENV=production \
    NODE_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true

# Install runtime-only dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      libpq5 \
      postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js runtime (required by some production assets)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd --system rails && \
    useradd --system --gid rails --home /app --shell /bin/bash rails

WORKDIR /app

# Copy installed gems from dependencies stage
COPY --from=dependencies /usr/local/bundle /usr/local/bundle

# Copy precompiled assets
COPY --from=assets /app/public/assets ./public/assets

# Copy application source code
COPY --chown=rails:rails . .

# Copy and configure entrypoint
COPY docker/entrypoints/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER rails

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
