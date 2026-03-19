# =============================================================================
# config/routes.rb
# =============================================================================

Rails.application.routes.draw do
  # Health check used by Docker and load balancers
  get "/health", to: "health#show"

  # Sidekiq Web UI
  require "sidekiq/web"
  if Rails.env.production?
    sidekiq_username = ENV.fetch("SIDEKIQ_USERNAME")
    sidekiq_password = ENV.fetch("SIDEKIQ_PASSWORD")

    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      username_ok = ActiveSupport::SecurityUtils.secure_compare(
        ::Digest::SHA256.hexdigest(username),
        ::Digest::SHA256.hexdigest(sidekiq_username)
      )
      password_ok = ActiveSupport::SecurityUtils.secure_compare(
        ::Digest::SHA256.hexdigest(password),
        ::Digest::SHA256.hexdigest(sidekiq_password)
      )

      username_ok && password_ok
    end
  end
  mount Sidekiq::Web => "/sidekiq"

  # PWA routes (Rails 8)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root
  # root "home#index"

  # Define your routes here:
  # resources :articles
  # namespace :api do
  #   namespace :v1 do
  #     resources :users
  #   end
  # end
end
