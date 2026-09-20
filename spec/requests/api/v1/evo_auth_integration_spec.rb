# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe 'EvoAuth integration through API auth filter', type: :request do
  let(:base_url) { 'http://auth.test' }
  let(:validate_url) { "#{base_url}/api/v1/auth/validate" }
  let(:token) { 'test-bearer-token' }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }
  let!(:user) { User.create!(name: 'Auth User', email: 'auth-user@example.com') }

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

  it 'propagates forbidden status and upstream error code' do
    stub_request(:post, validate_url)
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(
        status: 403,
        body: {
          success: false,
          error: {
            code: 'FORBIDDEN',
            message: 'Access denied for account context'
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    get '/api/v1/profile', headers: headers

    parsed = JSON.parse(response.body)
    expect(response).to have_http_status(:forbidden)
    expect(parsed.dig('error', 'code')).to eq('FORBIDDEN')
  end

  it 'propagates unprocessable_entity status and upstream error code' do
    stub_request(:post, validate_url)
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(
        status: 422,
        body: {
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Malformed MFA payload'
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    get '/api/v1/profile', headers: headers

    parsed = JSON.parse(response.body)
    expect(response).to have_http_status(:unprocessable_content)
    expect(parsed.dig('error', 'code')).to eq('VALIDATION_ERROR')
  end

  it 'maps forbidden status without upstream code to standardized FORBIDDEN code' do
    stub_request(:post, validate_url)
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(
        status: 403,
        body: {
          success: false,
          error: {
            message: 'Access denied'
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    get '/api/v1/profile', headers: headers, as: :json

    parsed = JSON.parse(response.body)
    expect(response).to have_http_status(:forbidden)
    expect(parsed.dig('error', 'code')).to eq(ApiErrorCodes::FORBIDDEN)
  end

  it 'maps unprocessable status without upstream code to standardized VALIDATION_ERROR code' do
    stub_request(:post, validate_url)
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(
        status: 422,
        body: {
          success: false,
          error: {
            message: 'Malformed MFA activation payload'
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    get '/api/v1/profile', headers: headers, as: :json

    parsed = JSON.parse(response.body)
    expect(response).to have_http_status(:unprocessable_content)
    expect(parsed.dig('error', 'code')).to eq(ApiErrorCodes::VALIDATION_ERROR)
  end

  it 'maps malformed auth-service payload to service unavailable' do
    stub_request(:post, validate_url)
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(status: 200, body: '{invalid-json', headers: { 'Content-Type' => 'application/json' })

    get '/api/v1/profile', headers: headers

    parsed = JSON.parse(response.body)
    expect(response).to have_http_status(:service_unavailable)
    expect(parsed.dig('error', 'code')).to eq('SERVICE_UNAVAILABLE')
  end

  it 'maps blank auth-service payload to service unavailable' do
    stub_request(:post, validate_url)
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })

    get '/api/v1/profile', headers: headers, as: :json

    parsed = JSON.parse(response.body)
    expect(response).to have_http_status(:service_unavailable)
    expect(parsed.dig('error', 'code')).to eq(ApiErrorCodes::SERVICE_UNAVAILABLE)
  end

  it 'accepts valid auth-service payload and reaches authenticated profile action' do
    stub_request(:post, validate_url)
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(
        status: 200,
        body: {
          success: true,
          data: {
            user: { id: user.id, email: user.email }
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    # EvoAuthConcern resolves conversations.read_all for every non-admin
    # request (Current.evo_can_read_all_inboxes); stub it or WebMock 500s.
    stub_request(:post, "#{base_url}/api/v1/users/#{user.id}/check_permission")
      .to_return(status: 200, body: { success: true, data: { has_permission: false } }.to_json,
                 headers: { 'Content-Type' => 'application/json' })

    get '/api/v1/profile', headers: headers, as: :json

    expect(response).to have_http_status(:ok)
  end
end
