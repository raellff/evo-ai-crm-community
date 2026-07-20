require 'digest'
require 'base64'
require 'json'

module EvoAuthConcern
  extend ActiveSupport::Concern

  AUTH_VALIDATE_CACHE_TTL = 20.seconds

  private

  def authenticate_user_with_evo_auth(token, token_type)
    Current.evo_auth_validation_cache ||= {}
    cache_key = evo_auth_validation_cache_key(token, token_type)
    user_data = Current.evo_auth_validation_cache[cache_key]

    auth_service = EvoAuthService.new
    unless user_data
      store_key = evo_auth_validation_store_key(cache_key)
      user_data = Rails.cache.read(store_key)

      unless user_data
        user_data = auth_service.validate_token(token: token, token_type: token_type)
        ttl = auth_validation_cache_ttl(token, token_type)
        Rails.cache.write(store_key, user_data, expires_in: ttl) if ttl.positive?
      end
    end

    Current.evo_auth_validation_cache[cache_key] = user_data

    set_current_user_from_auth_data(user_data, token, token_type)
    true
  rescue EvoAuthService::ValidationError => e
    Rails.logger.warn "EvoAuth: Token validation failed: #{e.message}"
    error_code = e.code.presence || ApiErrorCodes::UNAUTHORIZED
    error_status = e.status.presence || :unauthorized
    error_response(error_code, e.message, status: error_status)
    false
  rescue EvoAuthService::AuthenticationError => e
    Rails.logger.error "EvoAuth: Authentication service error: #{e.message}"
    error_response(ApiErrorCodes::SERVICE_UNAVAILABLE, 'Authentication service unavailable', status: :service_unavailable)
    false
  end

  def bearer_token_present?
    request.headers['Authorization']&.start_with?('Bearer ')
  end

  def set_current_user_from_auth_data(user_data, token, token_type)
    user = find_local_user(user_data['user'])
    raise EvoAuthService::ValidationError, 'User not found locally' unless user

    # Set current user
    Current.user = user
    @current_user = user
    Current.authentication_method = token_type

    # Store role key from evo-auth for permission checks
    role_key = user_data.dig('user', 'role', 'key') || user_data.dig('role', 'key')
    Current.evo_role_key = role_key

    Current.account = resolve_account(user_data['accounts'])
    user.update!(account_id: Current.account.id) if Current.account && user.account_id != Current.account.id

    # Store tokens for downstream services
    if token_type == 'bearer'
      Current.bearer_token = token
    elsif token_type == 'api_access_token'
      Current.api_access_token = token
    end
  end

  def find_local_user(user_data)
    return nil unless user_data

    User.find_by(email: user_data['email']) || User.find_by(id: user_data['id'])
  end

  # Finds (or creates) the CRM backend's own local mirror of the Account the
  # auth-service says this token belongs to, and refreshes it from the
  # auth-service's response on every request - including its feature
  # overrides (see specs/account-feature-toggles). See
  # specs/multi-account-tenancy/04-architecture.md, Decisions 7 and 11, and
  # specs/account-feature-toggles/04-architecture.md, Decision B2.
  def resolve_account(accounts_data)
    account_data = accounts_data&.first
    return nil unless account_data.present? && account_data['id'].present?

    account = Account.find_or_initialize_by(id: account_data['id'])
    is_new_account = account.new_record?

    account.assign_attributes(
      name: account_data['name'].presence || 'Account',
      subdomain: account_data['subdomain'].presence || account.subdomain || account_data['id'],
      support_email: account_data['support_email'],
      locale: account_data['locale'].presence || 'pt-BR',
      status: account_data['status'].presence || 'active',
      settings: account_data['settings'] || {},
      custom_attributes: account_data['custom_attributes'] || {}
    )

    apply_default_features(account) if is_new_account
    apply_feature_overrides(account, account_data['features'])

    account.save!
    account
  end

  # A brand-new local Account mirror starts from features.yml's installation
  # defaults, same as any other Chatwoot-derived account would via
  # Featurable#enable_default_features - except that callback is a no-op in
  # this fork (no ACCOUNT_LEVEL_FEATURE_DEFAULTS InstallationConfig exists),
  # so this is the actual mechanism that applies them.
  def apply_default_features(account)
    default_enabled_names = Featurable::FEATURE_LIST.select { |f| f['enabled'] }.pluck('name')
    account.enable_features(*default_enabled_names)
  end

  # Applies the auth-service's per-Account feature_overrides onto the local
  # Featurable bitmask. Unknown names (e.g. a feature this CRM version
  # doesn't know about yet) are ignored rather than raising - see
  # specs/account-feature-toggles/04-architecture.md, Decision A3.
  def apply_feature_overrides(account, overrides)
    return unless overrides.is_a?(Hash)

    known_names = Featurable::FEATURE_LIST.pluck('name')
    to_enable = []
    to_disable = []

    overrides.each do |name, enabled|
      next unless known_names.include?(name.to_s)

      (ActiveModel::Type::Boolean.new.cast(enabled) ? to_enable : to_disable) << name
    end

    account.enable_features(*to_enable)
    account.disable_features(*to_disable)
  end

  # Override current_user method to return our authenticated user
  def current_user
    @current_user || Current.user
  end

  def evo_auth_validation_cache_key(token, token_type)
    "#{token_type}:#{Digest::SHA256.hexdigest(token.to_s)}"
  end

  def evo_auth_validation_store_key(cache_key)
    "evo_auth:validate:#{cache_key}"
  end

  def auth_validation_cache_ttl(token, token_type)
    ttl = AUTH_VALIDATE_CACHE_TTL
    return ttl unless token_type.to_s == 'bearer'

    payload = decode_jwt_payload(token)
    return ttl unless payload.is_a?(Hash) && payload['exp'].present?

    remaining = payload['exp'].to_i - Time.now.to_i
    return 0.seconds if remaining <= 0

    [ttl, remaining.seconds].min
  rescue StandardError
    ttl
  end

  def decode_jwt_payload(token)
    segments = token.to_s.split('.')
    return {} if segments.length < 2

    payload_segment = segments[1]
    padding = '=' * ((4 - payload_segment.length % 4) % 4)
    decoded = Base64.urlsafe_decode64("#{payload_segment}#{padding}")
    JSON.parse(decoded)
  rescue StandardError
    {}
  end
end
