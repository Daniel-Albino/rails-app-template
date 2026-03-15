# =============================================================================
# config/routes.rb
# =============================================================================

Rails.application.routes.draw do
  # Health check — usado pelo Docker e load balancers
  get "/health", to: "health#show"

  # Sidekiq Web UI (apenas autenticado em produção)
  require "sidekiq/web"
  if Rails.env.production?
    # Em produção: protege com autenticação básica ou Devise
    # Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    #   ActiveSupport::SecurityUtils.secure_compare(
    #     ::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])
    #   ) &
    #   ActiveSupport::SecurityUtils.secure_compare(
    #     ::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"])
    #   )
    # end
  end
  mount Sidekiq::Web => "/sidekiq"

  # PWA routes (Rails 8)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root
  # root "home#index"

  # Define as tuas rotas aqui:
  # resources :articles
  # namespace :api do
  #   namespace :v1 do
  #     resources :users
  #   end
  # end
end
