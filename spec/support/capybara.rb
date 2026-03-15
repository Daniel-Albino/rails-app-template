# =============================================================================
# spec/support/capybara.rb
# Configuração do Capybara para testes de integração (feature specs).
# =============================================================================

require "capybara/rspec"

Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.server = :puma, { Silent: true }
end

# Driver padrão — headless Chrome
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end
end
