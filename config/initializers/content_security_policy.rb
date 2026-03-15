# =============================================================================
# config/initializers/content_security_policy.rb
# Content Security Policy — protege contra XSS e injecção de scripts.
# =============================================================================

# Rails.application.configure do
#   config.content_security_policy do |policy|
#     policy.default_src :self, :https
#     policy.font_src    :self, :https, :data
#     policy.img_src     :self, :https, :data
#     policy.object_src  :none
#     policy.script_src  :self, :https
#     policy.style_src   :self, :https
#
#     # Action Cable / WebSockets
#     policy.connect_src :self, :https, "http://localhost:3000", "ws://localhost:3000"
#
#     # Nonce para scripts inline (Turbo/Stimulus)
#     policy.script_src  *policy.script_src, :strict_dynamic, "'nonce-#{SecureRandom.base64(16)}'"
#   end
#
#   # Gera nonce automático para cada request
#   config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
#   config.content_security_policy_nonce_directives = %w[script-src]
# end
