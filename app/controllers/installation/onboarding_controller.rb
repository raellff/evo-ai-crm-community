class Installation::OnboardingController < ApplicationController
  before_action :ensure_installation_onboarding

  def index; end

  def create
    # Installation bootstrap now happens exclusively through the
    # auth-service's /setup/bootstrap (see SetupBootstrapService), which
    # creates the user, the real Account, and the superadmin role. This
    # action is unreachable in practice today (EVOLUTION_INSTALLATION_ONBOARDING
    # is never set — see ensure_installation_onboarding), but previously
    # called a nonexistent `AccountBuilder`.
    finish_onboarding
    redirect_to '/'
  end

  private

  def onboarding_params
    params.permit(:subscribe_to_updates, user: [:name, :company, :email])
  end

  def finish_onboarding
    ::Redis::Alfred.delete(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING)
    return if onboarding_params[:subscribe_to_updates].blank?

    EvolutionHubTelemetry.register_instance(
      onboarding_params.dig(:user, :company),
      onboarding_params.dig(:user, :name),
      onboarding_params.dig(:user, :email)
    )
  end

  def ensure_installation_onboarding
    redirect_to '/' unless ::Redis::Alfred.get(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING)
  end
end
