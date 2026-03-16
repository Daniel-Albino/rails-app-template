# =============================================================================
# Gemfile - Rails 8.0 tested compatible stack
# =============================================================================

source "https://rubygems.org"

ruby "3.3.6"

# Core
gem "puma", ">= 5.0"
gem "rails", "~> 8.0.0"

# Database
gem "pg", "~> 1.1"

# Cache & background jobs
gem "redis", "~> 5.0"
gem "sidekiq", "~> 7.0"

# Assets & frontend (native Rails 8 stack)
gem "importmap-rails"
gem "propshaft"
gem "stimulus-rails"
gem "turbo-rails"

# Authentication
gem "bcrypt", "~> 3.1.7"

# Utilities
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

# Image processing (ActiveStorage)
gem "image_processing", "~> 1.2"

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "debug", platforms: %i[mri windows]
  gem "dotenv-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "rspec-rails", "~> 7.0"
  gem "rubocop", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "bullet"
  gem "letter_opener_web"
  gem "rack-mini-profiler"
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "database_cleaner-active_record"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
end

group :production do
  gem "lograge"
end
