# =============================================================================
# config/initializers/inflections.rb
# Regras de inflexão personalizadas para palavras em Português.
# =============================================================================

ActiveSupport::Inflector.inflections(:pt) do |inflect|
  # Palavras irregulares (singular => plural)
  inflect.irregular "utilizador",  "utilizadores"
  inflect.irregular "artigo",      "artigos"
  inflect.irregular "categoria",   "categorias"
  inflect.irregular "permissao",   "permissoes"

  # Palavras invariáveis
  inflect.uncountable %w[informacao feedback]
end

ActiveSupport::Inflector.inflections(:en) do |inflect|
  # Adiciona aqui as tuas palavras irregulares em inglês
  # inflect.irregular "person", "people"
end
