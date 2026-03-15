# =============================================================================
# config/puma.rb
# Configuração do servidor Puma.
# =============================================================================

# Número de threads por worker
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Workers em produção (processos separados)
worker_count = ENV.fetch("WEB_CONCURRENCY", 2).to_i
if worker_count > 1 && !ENV["RAILS_ENV"].to_s.start_with?("development")
  workers worker_count
end

# Porta
port ENV.fetch("PORT", 3000)

# Ambiente
environment ENV.fetch("RAILS_ENV", "development")

# PID file
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Plugin para gestão de workers
plugin :tmp_restart

# Preload app para melhor performance com múltiplos workers
preload_app!

# Reconecta à DB após fork (com múltiplos workers)
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end
