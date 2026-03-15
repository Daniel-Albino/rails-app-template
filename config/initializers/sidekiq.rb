# =============================================================================
# config/initializers/sidekiq.rb
# Configuração do Sidekiq 7+ para background jobs.
# Na versão 7, a configuração Redis é feita via REDIS_URL directamente.
# =============================================================================

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
