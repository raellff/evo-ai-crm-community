# frozen_string_literal: true

# Overrides ActiveStorage::Blob.service so the storage provider chosen in Admin
# Settings → Storage is honoured at request time, not only at boot.
#
# GlobalConfigService.load reads from installation_configs via GlobalConfig
# (Redis-cached, invalidated on save via GlobalConfig.set).  Web workers and
# Sidekiq jobs both call through this path, so they converge within one cache
# cycle after the admin switches providers.
#
# Caveat: S3 credentials are still read at boot from config/storage.yml ERB —
# changing them in the UI requires a service restart.
Rails.application.config.after_initialize do
  next if ActiveStorage::Blob.respond_to?(:_static_service)

  ActiveStorage::Blob.class_eval do
    BUCKET_BACKED_SERVICES = %w[s3_compatible amazon google microsoft].freeze

    class << self
      alias_method :_static_service, :service

      def service
        service_name = GlobalConfigService.load(
          'ACTIVE_STORAGE_SERVICE',
          ENV.fetch('ACTIVE_STORAGE_SERVICE', 'local')
        ).presence || 'local'

        # Fail-safe: if a bucket-backed service is selected but no bucket is
        # configured, aws-sdk raises at every request and self-hosted stacks
        # become unusable. Fall back to :local so the CRM stays functional
        # instead of crashing (EVO-1961).
        if BUCKET_BACKED_SERVICES.include?(service_name) && !bucket_configured?(service_name)
          Rails.logger.warn("[ActiveStorage] '#{service_name}' selected but bucket not configured; falling back to :local")
          service_name = 'local'
        end

        key = service_name.to_sym
        resolved = respond_to?(:services) ? services.fetch(key) { nil } : nil
        unless resolved
          Rails.logger.warn("[ActiveStorage] service '#{service_name}' not registered (built at boot); falling back to boot-time default")
        end
        resolved || _static_service
      rescue StandardError => e
        Rails.logger.warn("[ActiveStorage] failed to resolve dynamic service: #{e.message}; falling back to boot-time default")
        _static_service
      end

      private

      def bucket_configured?(service_name)
        bucket_env = service_name == 'amazon' ? 'S3_BUCKET_NAME' : 'STORAGE_BUCKET_NAME'
        bucket = begin
          GlobalConfigService.load(bucket_env, ENV.fetch(bucket_env, nil))
        rescue StandardError
          ENV.fetch(bucket_env, nil)
        end
        bucket.to_s.strip.present?
      end
    end
  end
end
