# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

# Coverage for specs/account-feature-toggles Step 2: resolve_account
# (evo_auth_concern.rb) refreshing the local Account mirror - including its
# feature_flags bitmask - from the auth-service's response on every request,
# instead of only at first sight. See 02-prd.md acceptance criteria #6, #8.
RSpec.describe 'EvoAuth account sync (resolve_account)', type: :request do
  let(:base_url) { 'http://auth.test' }
  let(:validate_url) { "#{base_url}/api/v1/auth/validate" }
  let(:token) { 'test-bearer-token' }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }
  let!(:user) { User.create!(name: 'Sync User', email: 'sync-user@example.com') }
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

  def stub_validate(account_attrs)
    stub_request(:post, validate_url)
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(
        status: 200,
        body: {
          success: true,
          data: {
            user: { id: user.id, email: user.email },
            accounts: [{ id: account_id, name: 'Acme', subdomain: 'acme', status: 'active' }.merge(account_attrs)]
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  it 'creates a local Account with features.yml defaults plus the given overrides' do
    stub_validate('features' => { 'pipelines' => false })

    get '/api/v1/profile', headers: headers, as: :json

    expect(response).to have_http_status(:ok)
    account = Account.find(account_id)
    expect(account.feature_pipelines?).to be false
    expect(account.feature_automations?).to be true # features.yml default, untouched by the override
  end

  it 'does not duplicate the Account row on a second request' do
    stub_validate('features' => {})

    get '/api/v1/profile', headers: headers, as: :json
    get '/api/v1/profile', headers: headers, as: :json

    expect(Account.where(id: account_id).count).to eq(1)
  end

  it 'refreshes an already-synced Account on every request, not just at first sight' do
    stub_validate('name' => 'Original Name', 'features' => { 'pipelines' => false })
    get '/api/v1/profile', headers: headers, as: :json
    expect(Account.find(account_id).name).to eq('Original Name')

    Rails.cache.clear
    Current.reset
    stub_validate('name' => 'Renamed Co', 'features' => { 'pipelines' => true })
    get '/api/v1/profile', headers: headers, as: :json

    account = Account.find(account_id)
    expect(account.name).to eq('Renamed Co')
    expect(account.feature_pipelines?).to be true
  end

  it 'leaves other feature flags untouched when only one override changes' do
    stub_validate('features' => { 'pipelines' => false, 'ai_agents' => true })
    get '/api/v1/profile', headers: headers, as: :json

    Rails.cache.clear
    Current.reset
    stub_validate('features' => { 'pipelines' => true })
    get '/api/v1/profile', headers: headers, as: :json

    account = Account.find(account_id)
    expect(account.feature_pipelines?).to be true
    expect(account.feature_ai_agents?).to be true
  end

  it 'ignores an override for a feature name the CRM does not know about, without erroring' do
    stub_validate('features' => { 'totally_unknown_future_feature' => true })

    get '/api/v1/profile', headers: headers, as: :json

    expect(response).to have_http_status(:ok)
    expect(Account.find(account_id)).to be_present
  end
end
