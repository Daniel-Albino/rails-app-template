# =============================================================================
# STAGE 1: base
# Imagem base partilhada por development e production.
# Instala dependências do sistema e configura o ambiente Ruby.
# =============================================================================
FROM ruby:3.3.6-slim AS base

# Argumentos de build
ARG APP_USER=rails
ARG APP_HOME=/app

# Variáveis de ambiente base
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    GEM_HOME=/usr/local/bundle \
    PATH="/usr/local/bundle/bin:$PATH" \
    APP_HOME=${APP_HOME}

WORKDIR ${APP_HOME}

# Instala dependências de sistema mínimas para o base
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      curl \
      gnupg2 \
      ca-certificates \
      libpq5 && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# STAGE 2: dependencies
# Instala todas as dependências de build (gems + node_modules).
# Separado para maximizar cache do Docker.
# =============================================================================
FROM base AS dependencies

# Instala dependências de build
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

# Instala Node.js 20 LTS + Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists/*

# Copia apenas os ficheiros de dependências para aproveitar cache
COPY Gemfile Gemfile.lock* ./

# Instala gems (cached se Gemfile não mudar)
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}/ruby/*/cache" \
           "${BUNDLE_PATH}/ruby/*/bundler/gems/*/.git"

# Copia package.json e instala dependências Node
COPY package.json yarn.lock* ./
RUN yarn install --no-frozen-lockfile

# =============================================================================
# STAGE 3: development
# Imagem para ambiente de desenvolvimento com hot reload e ferramentas de debug.
# =============================================================================
FROM dependencies AS development

ENV RAILS_ENV=development \
    NODE_ENV=development \
    RAILS_LOG_TO_STDOUT=true

# Instala ferramentas extras de dev (úteis mas não necessárias em prod)
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      vim \
      less \
      postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Copia entrypoint e scripts
COPY docker/entrypoints/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/scripts/install-system-dependencies.sh /usr/local/bin/install-system-dependencies.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
             /usr/local/bin/install-system-dependencies.sh

# Copia o código da aplicação
COPY . .

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

# =============================================================================
# STAGE 4: assets (produção — pré-compilação de assets)
# =============================================================================
FROM dependencies AS assets

ENV RAILS_ENV=production \
    NODE_ENV=production \
    SECRET_KEY_BASE=dummy_for_assets_precompile \
    RAILS_LOG_TO_STDOUT=true

COPY . .

RUN bundle exec rails assets:precompile

# =============================================================================
# STAGE 5: production
# Imagem final de produção — mínima, segura e otimizada.
# =============================================================================
FROM base AS production

ENV RAILS_ENV=production \
    NODE_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true

# Instala apenas dependências de runtime
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      libpq5 \
      postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Instala Node.js runtime (necessário para alguns assets em prod)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# Cria utilizador não-root para segurança
RUN groupadd --system rails && \
    useradd --system --gid rails --home /app --shell /bin/bash rails

WORKDIR /app

# Copia gems instaladas do stage de dependencies
COPY --from=dependencies /usr/local/bundle /usr/local/bundle

# Copia assets pré-compilados
COPY --from=assets /app/public/assets ./public/assets
COPY --from=assets /app/public/packs ./public/packs 2>/dev/null || true

# Copia o código da aplicação
COPY --chown=rails:rails . .

# Copia e configura entrypoint
COPY docker/entrypoints/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Muda para utilizador não-root
USER rails

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
