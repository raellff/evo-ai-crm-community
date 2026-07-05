# frozen_string_literal: true

require 'rails_helper'

# EVO-2013: an orphan EVOLUTION_INSTALLATION_ONBOARDING flag (users exist but the
# flag was never cleared) used to redirect every dashboard access to
# /installation/onboarding in a loop. The guard clears the flag instead.
RSpec.describe DashboardController, type: :controller do
  controller(described_class) do
    def index
      head :ok
    end
  end

  before { ::Redis::Alfred.delete(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING) }
  after { ::Redis::Alfred.delete(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING) }

  context 'when the onboarding flag is not set' do
    it 'serves the dashboard normally' do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when the onboarding flag is set on a virgin installation (no users)' do
    before { ::Redis::Alfred.set(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING, true) }

    it 'redirects to onboarding and keeps the flag' do
      get :index
      expect(response).to redirect_to('/installation/onboarding')
      expect(::Redis::Alfred.get(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING)).to be_present
    end
  end

  context 'when the onboarding flag went orphan (users already exist)' do
    before do
      ::Redis::Alfred.set(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING, true)
      User.create!(name: 'Existing Admin', email: 'existing-admin@evo.test')
    end

    it 'clears the flag and does not redirect (no onboarding loop)' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(::Redis::Alfred.get(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING)).to be_nil
    end
  end
end
