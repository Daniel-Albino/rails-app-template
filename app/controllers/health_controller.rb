# =============================================================================
# app/controllers/health_controller.rb
# Endpoint de health check para Docker e load balancers.
# GET /health → 200 OK se tudo estiver bem.
# =============================================================================

class HealthController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def show
    checks = {
      database: database_healthy?,
      redis: redis_healthy?,
      timestamp: Time.current.iso8601,
      environment: Rails.env,
      version: Rails.version
    }

    if checks[:database] && checks[:redis]
      render json: { status: "ok", checks: checks }, status: :ok
    else
      render json: { status: "error", checks: checks }, status: :service_unavailable
    end
  end

  private

  def database_healthy?
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue StandardError
    false
  end

  def redis_healthy?
    Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")).ping == "PONG"
  rescue StandardError
    false
  end
end
