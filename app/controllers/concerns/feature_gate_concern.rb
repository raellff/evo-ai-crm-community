# frozen_string_literal: true

# Gates controller actions behind an Account's feature_flags (see
# app/models/concerns/featurable.rb, config/features.yml, and
# specs/account-feature-toggles). Mirrors the require_permissions
# convention in EvoPermissionConcern - declare once per controller, applies
# to every action unless `only:` narrows it.
module FeatureGateConcern
  extend ActiveSupport::Concern

  class_methods do
    # require_feature :pipelines
    # require_feature :ai_agents, only: [:index, :show]
    def require_feature(feature_name, only: nil)
      known_names = Featurable::FEATURE_LIST.pluck('name')
      unless known_names.include?(feature_name.to_s)
        raise ArgumentError, "Unknown feature #{feature_name.inspect} - check config/features.yml"
      end

      options = only ? { only: only } : {}
      before_action(options) { check_feature_enabled!(feature_name) }
    end
  end

  private

  def check_feature_enabled!(feature_name)
    # Service tokens carry elevated, cross-account privileges - same bypass
    # EvoPermissionConcern#check_permission! already grants them.
    return if Current.service_authenticated == true
    return if Current.account&.feature_enabled?(feature_name)

    error_response(
      ApiErrorCodes::FEATURE_NOT_AVAILABLE,
      "The #{feature_name} feature is not enabled for this account",
      status: :forbidden
    )
  end
end
