# =============================================================================
# Gemfile — Rails 8.0 + stack testada e compatível
# =============================================================================

source "https://rubygems.org"

ruby "3.3.6"

# Core
gem "rails", "~> 8.0.0"
gem "puma", ">= 5.0"

# Base de dados
gem "pg", "~> 1.1"

# Cache & Background Jobs
gem "redis", "~> 5.0"
gem "sidekiq", "~> 7.0"

# Assets & Frontend (stack Rails 8 nativa)
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# Autenticação
gem "bcrypt", "~> 3.1.7"

# Utilitários
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

# Image processing (ActiveStorage)
gem "image_processing", "~> 1.2"

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "dotenv-rails"
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails"
  gem "faker"
  gem "rubocop", require: false
  gem "rubocop-rails-omakase", require: false
  gem "brakeman", require: false
end

group :development do
  gem "web-console"
  gem "rack-mini-profiler"
  gem "bullet"
  gem "letter_opener_web"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
  gem "database_cleaner-active_record"
end

group :production do
  gem "lograge"
end
