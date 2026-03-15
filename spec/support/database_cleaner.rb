# =============================================================================
# spec/support/database_cleaner.rb
# Garante que a base de dados fica limpa entre testes.
# =============================================================================

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning { example.run }
  end

  # Specs com JS usam truncation (Capybara com driver JS não suporta transactions)
  config.before(:each, :js) do
    DatabaseCleaner.strategy = :truncation
  end

  config.after(:each, :js) do
    DatabaseCleaner.strategy = :transaction
  end
end
