# Resolves effective ActiveStorage URL options, honoring ENV['ACTIVE_STORAGE_URL']
# when present so generated URLs target a host reachable from the consumer.
#
# CAUTION: ActiveStorage::Current.url_options (with_scoped_url_options) only
# affects service-generated URLs (blob.url on DiskService). Rails route helpers
# (url_for, rails_storage_proxy_url) ignore it — pass effective_url_options as
# explicit route options instead.
#
# Used by:
# - Outbound media URLs handed to Evolution API / Evolution Go (outbound_media_url)
# - Redirect-mode DiskService signed URLs (with_scoped_url_options around blob.url)
module BlobUrlOptions
  module_function

  def effective_url_options(base = Rails.application.routes.default_url_options)
    base = (base || {}).dup
    return base if ENV['ACTIVE_STORAGE_URL'].blank?

    storage_uri = URI.parse(ENV['ACTIVE_STORAGE_URL'])
    base.merge(
      host: storage_uri.host,
      port: storage_uri.port,
      protocol: storage_uri.scheme
    )
  rescue URI::InvalidURIError => e
    Rails.logger.warn "[BlobUrlOptions] Invalid ACTIVE_STORAGE_URL=#{ENV['ACTIVE_STORAGE_URL'].inspect}: #{e.message}. Falling back to default_url_options."
    base
  end

  # Scopes ActiveStorage::Current.url_options to effective_url_options for the
  # duration of the block, restoring whatever was set before. Use this around
  # any url_for(blob_or_attached) / blob.url call so the generated host honors
  # ENV['ACTIVE_STORAGE_URL'] without leaking the override to unrelated callers.
  def with_scoped_url_options
    previous = ActiveStorage::Current.url_options
    ActiveStorage::Current.url_options = effective_url_options
    yield
  ensure
    ActiveStorage::Current.url_options = previous
  end

  # Media URL handed to external providers (Evolution API / Evolution Go).
  #
  # Proxy mode (default): app-served route with an EXPIRING signed id — the
  # storage endpoint stays private and the provider only needs to reach the
  # app host (ACTIVE_STORAGE_URL overrides it; falls back to BACKEND_URL).
  # Redirect mode (ATTACHMENT_DELIVERY=redirect): presigned storage URL, which
  # requires the storage host itself to be reachable by the provider — with
  # S3/MinIO the host is part of the SigV4 signature and cannot be rewritten.
  #
  # The TTL is 15 minutes (not the Rails default of 5) so slow providers have
  # time to fetch large video/PDF files; expired links return 404.
  def outbound_media_url(blob, expires_in: 15.minutes)
    if ActiveStorage.resolve_model_to_route == :rails_storage_proxy
      Rails.application.routes.url_helpers.rails_storage_proxy_url(
        blob, expires_in: expires_in, **effective_url_options
      )
    else
      with_scoped_url_options { blob.url(expires_in: expires_in) }
    end
  end
end
