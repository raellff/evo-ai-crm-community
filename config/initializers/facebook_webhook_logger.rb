# Register middleware to intercept Facebook webhook requests and log/process feed events
# This middleware runs before the facebook-messenger gem processes messaging events
# Require the middleware class explicitly before registering
require_relative '../../app/middleware/facebook_webhook_logger'

# Insert before ActionDispatch::Static when it exists (RAILS_SERVE_STATIC_FILES=true).
# With static files disabled (=false) that middleware is NOT in the stack and insert_before
# breaks the boot ("No such middleware to insert before: ActionDispatch::Static") -> in that
# case insert at the top of the stack, keeping the logger early enough.
if Rails.application.config.public_file_server.enabled
  Rails.application.config.middleware.insert_before ActionDispatch::Static, FacebookWebhookLogger
else
  Rails.application.config.middleware.insert_before 0, FacebookWebhookLogger
end

