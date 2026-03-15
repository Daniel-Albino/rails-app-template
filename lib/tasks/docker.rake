# =============================================================================
# lib/tasks/docker.rake
# Rake tasks para operações Docker comuns.
# Correr com: docker compose run --rm web rails docker:<task>
# =============================================================================

namespace :docker do
  desc "Limpa imagens Docker não utilizadas do projecto"
  task :clean do
    puts "== A limpar imagens Docker antigas =="
    system "docker image prune -f --filter label=app=my_app"
  end

  desc "Mostra informação sobre o ambiente Docker actual"
  task :info do
    puts "\n== Informação do Ambiente ==\n"
    puts "  Rails:      #{Rails.version}"
    puts "  Ruby:       #{RUBY_VERSION}"
    puts "  Ambiente:   #{Rails.env}"
    puts "  BD URL:     #{ENV['DATABASE_URL'] || 'não definido'}"
    puts "  Redis URL:  #{ENV['REDIS_URL'] || 'não definido'}"
    puts "  Node:       #{`node --version 2>/dev/null`.strip}"
    puts "  Yarn:       #{`yarn --version 2>/dev/null`.strip}"
    puts ""
  end

  desc "Verifica conectividade com PostgreSQL e Redis"
  task health: :environment do
    puts "\n== Health Check =="

    # PostgreSQL
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      puts "  [OK] PostgreSQL — conectado"
    rescue StandardError => e
      puts "  [FAIL] PostgreSQL — #{e.message}"
    end

    # Redis
    begin
      redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
      redis.ping
      puts "  [OK] Redis — conectado"
    rescue StandardError => e
      puts "  [FAIL] Redis — #{e.message}"
    end

    puts ""
  end
end
