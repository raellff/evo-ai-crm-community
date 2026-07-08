# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

# The WhatsApp channel-management trees (evolution/*, evolution_go/*, zapi/*)
# proxy channel mutations to the provider APIs. Every routed action is gated by
# an inboxes.* permission: reads require inboxes.read; writes require
# inboxes.create/update/delete. A user holding only inboxes.read (the seeded
# agent grant) must get 403 on every write action while keeping read access.
RSpec.describe 'WhatsApp channel management RBAC', type: :request do
  write_endpoints = [
    # evolution/*
    [:post,   '/api/v1/evolution/authorization'],
    [:post,   '/api/v1/evolution/qrcodes'],
    [:post,   '/api/v1/evolution/proxies'],
    [:post,   '/api/v1/evolution/settings'],
    [:patch,  '/api/v1/evolution/settings/spec-instance'],
    [:patch,  '/api/v1/evolution/privacy/spec-instance'],
    [:delete, '/api/v1/evolution/instances/spec-instance/logout'],
    [:post,   '/api/v1/evolution/profile/spec-instance/name'],
    [:post,   '/api/v1/evolution/profile/spec-instance/status'],
    [:post,   '/api/v1/evolution/profile/spec-instance/picture'],
    [:delete, '/api/v1/evolution/profile/spec-instance/picture'],
    # evolution_go/*
    [:post,   '/api/v1/evolution_go/authorization'],
    [:post,   '/api/v1/evolution_go/authorization/connect'],
    [:delete, '/api/v1/evolution_go/authorization/logout'],
    [:delete, '/api/v1/evolution_go/authorization/delete_instance'],
    [:post,   '/api/v1/evolution_go/qrcodes'],
    [:patch,  '/api/v1/evolution_go/settings/spec-uuid'],
    [:patch,  '/api/v1/evolution_go/privacy/spec-uuid'],
    [:post,   '/api/v1/evolution_go/profile/picture'],
    [:post,   '/api/v1/evolution_go/profile/spec-uuid/name'],
    [:post,   '/api/v1/evolution_go/profile/spec-uuid/status'],
    [:post,   '/api/v1/evolution_go/profile/spec-uuid/picture'],
    [:delete, '/api/v1/evolution_go/profile/spec-uuid/picture'],
    # zapi/*
    [:post,   '/api/v1/zapi/qrcodes'],
    [:post,   '/api/v1/zapi/qrcodes/spec-instance'],
    [:put,    '/api/v1/zapi/settings/spec-instance/update_profile_picture'],
    [:put,    '/api/v1/zapi/settings/spec-instance/update_profile_name'],
    [:put,    '/api/v1/zapi/settings/spec-instance/update_instance_name'],
    [:put,    '/api/v1/zapi/settings/spec-instance/update_profile_description'],
    [:put,    '/api/v1/zapi/settings/spec-instance/update_call_reject'],
    [:put,    '/api/v1/zapi/settings/spec-instance/update_call_reject_message'],
    [:post,   '/api/v1/zapi/settings/spec-instance/restart'],
    [:post,   '/api/v1/zapi/settings/spec-instance/disconnect'],
    [:post,   '/api/v1/zapi/settings/spec-instance/privacy_set_last_seen'],
    [:post,   '/api/v1/zapi/settings/spec-instance/privacy_set_photo_visualization'],
    [:post,   '/api/v1/zapi/settings/spec-instance/privacy_set_description'],
    [:post,   '/api/v1/zapi/settings/spec-instance/privacy_set_group_add_permission'],
    [:post,   '/api/v1/zapi/settings/spec-instance/privacy_set_online'],
    [:post,   '/api/v1/zapi/settings/spec-instance/privacy_set_read_receipts'],
    [:post,   '/api/v1/zapi/settings/spec-instance/privacy_set_messages_duration']
  ]

  read_endpoints = [
    # evolution/*
    [:get,  '/api/v1/evolution/health'],
    [:get,  '/api/v1/evolution/instances'],
    [:get,  '/api/v1/evolution/qrcodes/spec-instance'],
    [:get,  '/api/v1/evolution/proxies/spec-instance'],
    [:get,  '/api/v1/evolution/settings/spec-instance'],
    [:get,  '/api/v1/evolution/privacy/spec-instance'],
    [:post, '/api/v1/evolution/profile/spec-instance/fetch'],
    # evolution_go/*
    [:get,  '/api/v1/evolution_go/authorization/qrcode'],
    [:get,  '/api/v1/evolution_go/authorization/fetch'],
    [:get,  '/api/v1/evolution_go/qrcodes/spec-uuid'],
    [:get,  '/api/v1/evolution_go/settings/spec-uuid'],
    [:get,  '/api/v1/evolution_go/privacy/spec-uuid'],
    [:get,  '/api/v1/evolution_go/profile/spec-uuid'],
    [:post, '/api/v1/evolution_go/profile/info'],
    [:post, '/api/v1/evolution_go/profile/avatar'],
    # zapi/*
    [:get,  '/api/v1/zapi/qrcodes/spec-instance'],
    [:get,  '/api/v1/zapi/qrcodes/status'],
    [:get,  '/api/v1/zapi/settings/spec-instance'],
    [:get,  '/api/v1/zapi/settings/spec-instance/privacy_disallowed_contacts']
  ]

  let(:user) { User.create!(name: 'Perm Probe', email: "probe-#{SecureRandom.hex(4)}@example.com") }

  before do
    probe = user
    allow_any_instance_of(Api::BaseController).to receive(:authenticate_request!) do
      Current.user = probe
      Current.evo_permission_cache ||= {}
    end
  end

  after { Current.reset }

  def grant_permissions(*granted)
    allow_any_instance_of(EvoAuthService).to receive(:check_user_permission) do |_service, _user_id, permission|
      granted.include?(permission)
    end
  end

  context 'with only inboxes.read (agent grant)' do
    before { grant_permissions('inboxes.read') }

    write_endpoints.each do |method, path|
      it "denies #{method.to_s.upcase} #{path}" do
        public_send(method, path, as: :json)

        expect(response).to have_http_status(:forbidden)
      end
    end

    read_endpoints.each do |method, path|
      it "passes the gate on #{method.to_s.upcase} #{path}" do
        public_send(method, path, as: :json)

        expect(response).not_to have_http_status(:forbidden)
        expect(response).not_to have_http_status(:unauthorized)
      end
    end
  end

  context 'with the inboxes write permissions (admin grant)' do
    before { grant_permissions('inboxes.read', 'inboxes.create', 'inboxes.update', 'inboxes.delete') }

    write_endpoints.each do |method, path|
      it "passes the gate on #{method.to_s.upcase} #{path}" do
        public_send(method, path, as: :json)

        expect(response).not_to have_http_status(:forbidden)
        expect(response).not_to have_http_status(:unauthorized)
      end
    end

    it 'executes an Evolution write end-to-end (proxy settings)' do
      allow_any_instance_of(Api::V1::Evolution::ProxiesController)
        .to receive(:set_proxy).and_return({ 'proxy' => { 'enabled' => false } })

      post '/api/v1/evolution/proxies',
           params: { proxy: { instance_name: 'spec-instance', api_url: 'http://evolution.test',
                              api_hash: 'secret', proxy_settings: { enabled: false } } },
           as: :json

      expect(response).to have_http_status(:ok)
    end

    it 'executes an Evolution Go write end-to-end (advanced settings)' do
      allow_any_instance_of(Api::V1::EvolutionGo::SettingsController)
        .to receive(:update_advanced_settings).and_return({ 'updated' => true })

      patch '/api/v1/evolution_go/settings/spec-uuid',
            params: { settings: { api_url: 'http://evolution-go.test', instance_token: 'tok' } },
            as: :json

      expect(response).to have_http_status(:ok)
    end

    it 'executes a Z-API write end-to-end (restart)' do
      channel = Channel::Whatsapp.new(provider: 'zapi', phone_number: "+1555#{SecureRandom.hex(3)}",
                                      provider_config: { 'instance_id' => 'spec-instance', 'token' => 'tok' })
      channel.save!(validate: false)
      Inbox.create!(channel: channel, name: "ZAPI Inbox #{SecureRandom.hex(3)}")
      allow_any_instance_of(Api::V1::Zapi::SettingsController)
        .to receive(:restart_instance_api).and_return({ 'value' => true })

      post '/api/v1/zapi/settings/spec-instance/restart', as: :json

      expect(response).to have_http_status(:ok)
    end
  end
end
