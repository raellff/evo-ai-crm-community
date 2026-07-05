class Installation::OnboardingController < ApplicationController
  before_action :ensure_installation_onboarding

  def index; end

  def create
    begin
      AccountBuilder.new(
        account_name: onboarding_params.dig(:user, :company),
        user_full_name: onboarding_params.dig(:user, :name),
        email: onboarding_params.dig(:user, :email),
        user_password: params.dig(:user, :password),
        confirmed: true
      ).perform
    rescue StandardError => e
      redirect_to '/', flash: { error: e.message } and return
    end
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
    return redirect_to '/' unless ::Redis::Alfred.get(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING)

    # EVO-2013: on API-only deploys (EVOLUTION_API_ONLY_SERVER default true) the
    # dashboard routes are not drawn, so the dashboard-side guard never runs and an
    # orphan flag would keep these endpoints open forever. Same rule as there: an
    # existing User means the installation is not virgin — clear the flag and leave.
    return unless User.exists?

    ::Redis::Alfred.delete(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING)
    redirect_to '/'
  end
end
