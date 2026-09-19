# frozen_string_literal: true

# Configure ActiveStorage for development environment
Rails.application.configure do
  # Skip SSL verification for S3-compatible services in development
  # This fixes SSL certificate verification issues with Cloudflare R2 in local development
  if Rails.env.development?
    require 'aws-sdk-s3'

    Aws.config.update(
      ssl_verify_peer: false,
      http_wire_trace: false  # Desabilitar trace HTTP para não poluir logs com dados binários
    )

    Rails.logger.info "🔓 ActiveStorage: SSL verification disabled for development environment"
  end
end

# Warn at boot when storage redirects are used with local storage and no
# explicit public host. In redirect mode, media URLs point at the storage
# service: DiskService falls back to default_url_options (often the container's
# internal hostname), which neither the user's browser nor sibling containers
# (Evolution API) can resolve — the "grey blob" render bug and silent outbound
# delivery failures (EVO-1747). The default proxy mode (EVO-2006) serves files
# through the app, so reachability follows BACKEND_URL and this does not apply.
if !Rails.env.test? &&
   ENV.fetch('ATTACHMENT_DELIVERY', 'proxy').casecmp('redirect').zero? &&
   ENV['ACTIVE_STORAGE_SERVICE'].to_s.downcase == 'local' &&
   ENV['ACTIVE_STORAGE_URL'].to_s.strip.empty?
  Rails.logger.warn '⚠️  ATTACHMENT_DELIVERY=redirect with ACTIVE_STORAGE_SERVICE=local but ' \
                    'ACTIVE_STORAGE_URL is not set. Inbound media will likely not render in ' \
                    'the chat and outbound media will not be delivered. Set ACTIVE_STORAGE_URL ' \
                    'to a host reachable by both the browser and sibling containers, or unset ' \
                    'ATTACHMENT_DELIVERY to use the default proxy mode (see .env.example).'
end
