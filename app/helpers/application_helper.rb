# =============================================================================
# app/helpers/application_helper.rb
# Helpers globais disponíveis em todas as views.
# =============================================================================

module ApplicationHelper
  # Título dinâmico da página
  # Uso na view: content_for :title, "Página de Artigos"
  # No layout: <%= page_title %>
  def page_title(separator: " | ")
    base = "MyApp"
    return base unless content_for?(:title)

    "#{content_for(:title)}#{separator}#{base}"
  end

  # Classes CSS condicionais para flash messages
  def flash_class(type)
    {
      "notice" => "flash flash--notice",
      "success" => "flash flash--success",
      "alert" => "flash flash--alert",
      "error" => "flash flash--error",
      "warning" => "flash flash--warning"
    }.fetch(type.to_s, "flash flash--notice")
  end

  # Formata datas de forma consistente em PT
  def format_date(date, format: :long)
    return "" if date.blank?

    l(date.to_date, format: format)
  end

  def format_datetime(datetime, format: :long)
    return "" if datetime.blank?

    l(datetime, format: format)
  end

  # Renderiza ícone SVG inline (se usares uma biblioteca)
  # def icon(name, **options)
  #   content_tag :span, class: "icon icon--#{name}", **options do
  #     render "shared/icons/#{name}"
  #   end
  # end
end
