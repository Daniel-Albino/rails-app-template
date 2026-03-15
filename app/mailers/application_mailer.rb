# =============================================================================
# app/mailers/application_mailer.rb
# =============================================================================

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "noreply@my_app.com")
  layout "mailer"
end
