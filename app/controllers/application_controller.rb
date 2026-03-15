# =============================================================================
# app/controllers/application_controller.rb
# =============================================================================

class ApplicationController < ActionController::Base
  # Protecção CSRF
  protect_from_forgery with: :exception

  # Filtros globais de segurança
  before_action :set_locale

  private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  # Helper para APIs — responde com JSON em caso de erro
  def respond_with_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
end
