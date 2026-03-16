# =============================================================================
# config/puma.rb
# Puma server configuration.
# =============================================================================

# Thread count per worker
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Workers in production (separate processes)
worker_count = ENV.fetch("WEB_CONCURRENCY", 2).to_i
workers worker_count if worker_count > 1 && !ENV["RAILS_ENV"].to_s.start_with?("development")

# Port
port ENV.fetch("PORT", 3000)

# Environment
environment ENV.fetch("RAILS_ENV", "development")

# PID file
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Worker management plugin
plugin :tmp_restart

# Preload app for better performance with multiple workers
preload_app!

# Reconnect DB after fork (with multiple workers)
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end
