# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

# Coverage for specs/account-feature-toggles Step 3 (require_feature) and its
# follow-up extension to automations/integrations (requested by the user
# after seeing only Pipelines/AI Agents toggleable in the UI).
# See 02-prd.md acceptance criteria #1, #2.
RSpec.describe 'Feature gate (require_feature)', type: :request do
  let(:base_url) { 'http://auth.test' }
  let(:validate_url) { "#{base_url}/api/v1/auth/validate" }
  let(:token) { 'test-bearer-token' }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }
  let!(:user) { User.create!(name: 'Gate User', email: 'gate-user@example.com') }
  let(:account_id) { SecureRandom.uuid }

  around do |example|
    original_base_url = ENV['EVO_AUTH_SERVICE_URL']
    ENV['EVO_AUTH_SERVICE_URL'] = base_url
    Rails.cache.clear
    Current.reset
    example.run
    Rails.cache.clear
    Current.reset
    ENV['EVO_AUTH_SERVICE_URL'] = original_base_url
  end

  def stub_validate(features)
    stub_request(:post, validate_url)
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(
        status: 200,
        body: {
          success: true,
          data: {
            user: { id: user.id, email: user.email },
            accounts: [{ id: account_id, name: 'Acme', subdomain: 'acme', status: 'active', 'features' => features }]
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe 'Pipelines' do
    it 'blocks index with 403 FEATURE_NOT_AVAILABLE when pipelines is disabled for the account' do
      stub_validate('pipelines' => false)

      get '/api/v1/pipelines', headers: headers, as: :json

      expect(response).to have_http_status(:forbidden)
      body = JSON.parse(response.body)
      expect(body.dig('error', 'code')).to eq('FEATURE_NOT_AVAILABLE')
    end

    it 'blocks create with 403 FEATURE_NOT_AVAILABLE when pipelines is disabled for the account' do
      stub_validate('pipelines' => false)

      post '/api/v1/pipelines', params: { pipeline: { name: 'New', pipeline_type: 'sales' } }, headers: headers, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body).dig('error', 'code')).to eq('FEATURE_NOT_AVAILABLE')
    end

    it 'never blocks a different Account whose pipelines feature is enabled' do
      stub_validate('pipelines' => false)
      allow_any_instance_of(EvoAuthService).to receive(:check_user_permission).and_return(true)

      get '/api/v1/pipelines', headers: headers, as: :json
      expect(response).to have_http_status(:forbidden)

      # A second, different Account with pipelines left at its features.yml default (enabled).
      Rails.cache.clear
      Current.reset
      other_user = User.create!(name: 'Other Gate User', email: 'other-gate-user@example.com')
      stub_request(:post, validate_url)
        .with(headers: { 'Authorization' => "Bearer other-token" })
        .to_return(
          status: 200,
          body: {
            success: true,
            data: {
              user: { id: other_user.id, email: other_user.email },
              accounts: [{ id: SecureRandom.uuid, name: 'Other Co', subdomain: 'other-co', status: 'active', 'features' => {} }]
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      get '/api/v1/pipelines', headers: { 'Authorization' => 'Bearer other-token' }, as: :json
      expect(response).to have_http_status(:ok)
    end

    it 'does not block the request when pipelines is left at its features.yml default (enabled)' do
      stub_validate({})
      allow_any_instance_of(EvoAuthService).to receive(:check_user_permission).and_return(true)

      get '/api/v1/pipelines', headers: headers, as: :json

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'Automations' do
    it 'blocks index with 403 FEATURE_NOT_AVAILABLE when automations is disabled for the account' do
      stub_validate('automations' => false)

      get '/api/v1/automation_rules', headers: headers, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body).dig('error', 'code')).to eq('FEATURE_NOT_AVAILABLE')
    end

    it 'does not block the request when automations is left at its features.yml default (enabled)' do
      stub_validate({})
      allow_any_instance_of(EvoAuthService).to receive(:check_user_permission).and_return(true)

      get '/api/v1/automation_rules', headers: headers, as: :json

      expect(response).to have_http_status(:ok)
    end

    it 'blocks before the permission check runs (feature gate takes precedence)' do
      stub_validate('automations' => false)
      # No permission stub at all - if the feature gate did NOT run first, this
      # would 403 for a different reason (missing permission), which would
      # mask a regression in ordering. Assert the FEATURE_NOT_AVAILABLE code
      # specifically to prove the feature gate is what fired.
      get '/api/v1/automation_rules', headers: headers, as: :json

      expect(JSON.parse(response.body).dig('error', 'code')).to eq('FEATURE_NOT_AVAILABLE')
    end
  end

  describe 'Integrations' do
    it 'blocks index with 403 FEATURE_NOT_AVAILABLE when integrations is disabled for the account' do
      stub_validate('integrations' => false)

      get '/api/v1/integrations/apps', headers: headers, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body).dig('error', 'code')).to eq('FEATURE_NOT_AVAILABLE')
    end

    it 'does not block the request when integrations is left at its features.yml default (enabled)' do
      stub_validate({})

      get '/api/v1/integrations/apps', headers: headers, as: :json

      expect(response).to have_http_status(:ok)
    end

    it 'never lets one Account\'s disabled integrations affect another Account' do
      stub_validate('integrations' => false)
      get '/api/v1/integrations/apps', headers: headers, as: :json
      expect(response).to have_http_status(:forbidden)

      Rails.cache.clear
      Current.reset
      other_user = User.create!(name: 'Other Integrations User', email: 'other-integrations-user@example.com')
      stub_request(:post, validate_url)
        .with(headers: { 'Authorization' => "Bearer other-token-2" })
        .to_return(
          status: 200,
          body: {
            success: true,
            data: {
              user: { id: other_user.id, email: other_user.email },
              accounts: [{ id: SecureRandom.uuid, name: 'Other Integrations Co', subdomain: 'other-integrations-co', status: 'active', 'features' => {} }]
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      get '/api/v1/integrations/apps', headers: { 'Authorization' => 'Bearer other-token-2' }, as: :json
      expect(response).to have_http_status(:ok)
    end
  end
end
