# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

# Pins that QrcodesController#set_instance_params resolves credentials through
# EvolutionGoConcern#evolution_go_credentials_for, so a refactor that drops the
# concern include or reverts to direct provider_config['api_url'] reads cannot
# silently regress legacy Evolution Go channels (the EVO-984 root cause).
RSpec.describe Api::V1::EvolutionGo::QrcodesController, type: :controller do
  describe '#set_instance_params' do
    let(:controller_instance) { described_class.new }
    let(:channel) do
      instance_double(
        Channel::Whatsapp,
        id: 'chan-uuid',
        provider_config: { 'api_url' => '', 'admin_token' => '', 'instance_token' => 'inst-tok',
                           'instance_uuid' => 'inst-uuid', 'instance_name' => 'inst-name' },
        inbox: instance_double(Inbox)
      )
    end

    before do
      controller_instance.params = ActionController::Parameters.new(id: 'inst-name')
      relation = double('relation')
      allow(Channel::Whatsapp).to receive(:joins).with(:inbox).and_return(relation)
      allow(relation).to receive(:where).and_return(relation)
      allow(relation).to receive(:first).and_return(channel)
    end

    it 'resolves api_url and admin_token from GlobalConfig when provider_config is empty' do
      allow(GlobalConfigService).to receive(:load).with('EVOLUTION_GO_API_URL', '').and_return('http://global.example.com')
      allow(GlobalConfigService).to receive(:load).with('EVOLUTION_GO_ADMIN_SECRET', '').and_return('global-secret')

      controller_instance.send(:set_instance_params)

      expect(controller_instance.instance_variable_get(:@api_url)).to eq('http://global.example.com')
      expect(controller_instance.instance_variable_get(:@instance_token)).to eq('inst-tok')
      expect(controller_instance.instance_variable_get(:@instance_uuid)).to eq('inst-uuid')
      expect(controller_instance.instance_variable_get(:@instance_name)).to eq('inst-name')
    end
  end

  # POST /qrcodes (refresh) é uma rota plana — não recebe :id. Antes do fix,
  # #create lia auth_params[:api_url] direto e respondia 400 quando o frontend
  # mandava só instance_uuid (canal legado pré-EVO-984), repetindo o sintoma da
  # issue. Estes testes pinam que o método agora resolve credenciais via canal.
  describe '#create credential resolution' do
    let(:controller_instance) { described_class.new }
    let(:channel) do
      instance_double(
        Channel::Whatsapp,
        id: 'chan-uuid',
        provider_config: { 'api_url' => '', 'instance_token' => 'inst-tok',
                           'instance_uuid' => 'inst-uuid', 'instance_name' => 'inst-name' },
        inbox: instance_double(Inbox)
      )
    end

    before do
      relation = double('relation')
      allow(Channel::Whatsapp).to receive(:joins).with(:inbox).and_return(relation)
      allow(relation).to receive(:where).and_return(relation)
      allow(relation).to receive(:first).and_return(channel)
    end

    it 'falls back to channel + GlobalConfig when payload has only instance_uuid' do
      controller_instance.params = ActionController::Parameters.new(qrcode: { instance_uuid: 'inst-uuid' })
      allow(GlobalConfigService).to receive(:load).with('EVOLUTION_GO_API_URL', '').and_return('http://global.example.com')
      allow(GlobalConfigService).to receive(:load).with('EVOLUTION_GO_ADMIN_SECRET', '').and_return('global-secret')
      allow(controller_instance).to receive(:get_qrcode_go).with('http://global.example.com', 'inst-tok').and_return(base64: 'x', code: 'y', connected: false)

      expect(controller_instance).to receive(:render).with(
        hash_including(json: hash_including(success: true))
      )

      controller_instance.create
    end

    it 'still 400s when channel lookup fails and payload is missing credentials' do
      relation = double('relation')
      allow(Channel::Whatsapp).to receive(:joins).with(:inbox).and_return(relation)
      allow(relation).to receive(:where).and_return(relation)
      allow(relation).to receive(:first).and_return(nil)
      allow(GlobalConfigService).to receive(:load).and_return('')

      controller_instance.params = ActionController::Parameters.new(qrcode: { instance_uuid: 'unknown-uuid' })

      expect(controller_instance).to receive(:render).with(
        hash_including(status: :bad_request)
      )

      controller_instance.create
    end
  end

  # Regression: Evolution Go's GET /instance/qr answers with LOWERCASE keys
  # ({"data":{"qrcode":"...","code":"..."}}), but get_qrcode_go used to read
  # 'Qrcode'/'Code' (capitalized) — a Hash lookup that never matches, so
  # base64/code came back nil on every real call. That still rendered HTTP
  # 200 (no exception raised), so the frontend silently showed its generic
  # QR-code error the instant the user clicked "Conectar dispositivo", even
  # though the provider call itself succeeded.
  describe '#get_qrcode_go' do
    let(:controller_instance) { described_class.new }

    it 'reads base64/code from the actual lowercase keys Evolution Go returns' do
      stub_request(:get, 'http://go.example.com/instance/qr')
        .to_return(
          status: 200,
          body: { data: { qrcode: 'data:image/png;base64,AAA', code: 'https://wa.me/…' },
                   message: 'success' }.to_json
        )

      result = controller_instance.send(:get_qrcode_go, 'http://go.example.com', 'inst-tok')

      expect(result).to eq(base64: 'data:image/png;base64,AAA', code: 'https://wa.me/…', connected: false)
    end

    it 'still works if a future response uses capitalized keys' do
      stub_request(:get, 'http://go.example.com/instance/qr')
        .to_return(
          status: 200,
          body: { data: { Qrcode: 'data:image/png;base64,BBB', Code: 'https://wa.me/…' },
                   message: 'success' }.to_json
        )

      result = controller_instance.send(:get_qrcode_go, 'http://go.example.com', 'inst-tok')

      expect(result).to eq(base64: 'data:image/png;base64,BBB', code: 'https://wa.me/…', connected: false)
    end
  end
end
