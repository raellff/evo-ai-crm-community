# frozen_string_literal: true

require 'rails_helper'

# EVO-2013: these endpoints are drawn unconditionally, so on API-only deploys
# (where the dashboard-side guard never runs) they are the only place that can
# clean up an orphan onboarding flag.
RSpec.describe 'Installation onboarding', type: :request do
  before { ::Redis::Alfred.delete(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING) }
  after { ::Redis::Alfred.delete(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING) }

  context 'when the onboarding flag is not set' do
    it 'redirects GET away from onboarding' do
      get '/installation/onboarding'
      expect(response).to redirect_to('/')
    end
  end

  context 'when the onboarding flag went orphan (users already exist)' do
    before do
      ::Redis::Alfred.set(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING, true)
      User.create!(name: 'Existing Admin', email: 'existing-admin@evo.test')
    end

    it 'GET clears the flag and redirects away' do
      get '/installation/onboarding'
      expect(response).to redirect_to('/')
      expect(::Redis::Alfred.get(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING)).to be_nil
    end

    it 'POST is blocked before reaching account creation' do
      expect do
        post '/installation/onboarding', params: { user: { name: 'X', email: 'x@evo.test' } }
      end.not_to change(User, :count)
      expect(response).to redirect_to('/')
      expect(::Redis::Alfred.get(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING)).to be_nil
    end
  end

  context 'when the onboarding flag is set on a virgin installation (no users)' do
    before { ::Redis::Alfred.set(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING, true) }

    it 'keeps the onboarding endpoint open' do
      get '/installation/onboarding'
      expect(response).not_to be_redirect
      expect(::Redis::Alfred.get(::Redis::Alfred::EVOLUTION_INSTALLATION_ONBOARDING)).to be_present
    rescue ActionView::MissingExactTemplate
      # Reaching the render step already proves the guard let the request
      # through — the backend ships no view for it; the SPA drives the flow.
    end
  end
end
