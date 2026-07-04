# Register middleware to intercept Facebook webhook requests and log/process feed events
# This middleware runs before the facebook-messenger gem processes messaging events
# Require the middleware class explicitly before registering
require_relative '../../app/middleware/facebook_webhook_logger'

# Insere antes do ActionDispatch::Static quando ele existe (RAILS_SERVE_STATIC_FILES=true).
# Com static desabilitado (=false) esse middleware NAO esta na stack, e o insert_before
# quebra o boot ("No such middleware to insert before: ActionDispatch::Static") -> nesse
# caso inserimos no topo da stack, mantendo o logger cedo o suficiente.
if Rails.application.config.public_file_server.enabled
  Rails.application.config.middleware.insert_before ActionDispatch::Static, FacebookWebhookLogger
else
  Rails.application.config.middleware.insert_before 0, FacebookWebhookLogger
end

