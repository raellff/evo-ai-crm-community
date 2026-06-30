# frozen_string_literal: true

begin
  require 'rails_helper'
rescue LoadError
  RSpec.describe 'Webhooks::WhatsappEventsJob' do
    it 'has spec scaffold ready' do
      skip 'rails_helper is not available in this workspace snapshot'
    end
  end
end

return unless defined?(Rails)

RSpec.describe Webhooks::WhatsappEventsJob do
  subject(:job) { described_class.new }

  describe '#message_event? (EVO-1967)' do
    it 'is true for evolution messages.upsert' do
      expect(job.send(:message_event?, { event: 'messages.upsert' })).to be(true)
    end

    it 'is false for connection.update / non-message events' do
      expect(job.send(:message_event?, { event: 'connection.update' })).to be(false)
    end
  end

  describe '#reconcile_channel_state! (EVO-1967 Fix B: active reconciliation)' do
    let(:provider_config) do
      { 'api_url' => 'http://evolution-api:8080', 'instance_name' => 'vendedor-2', 'instance_token' => 'k' }
    end
    let(:channel) do
      instance_double(Channel::Whatsapp, id: 1, provider: 'evolution', provider_config: provider_config)
    end

    before { allow(channel).to receive(:is_a?).with(Channel::Whatsapp).and_return(true) }

    it 'reauthorizes the channel and returns true when Evolution reports open' do
      allow(job).to receive(:evolution_connection_state).and_return('open')
      expect(channel).to receive(:reauthorized!)
      expect(job.send(:reconcile_channel_state!, channel, { instance: 'vendedor-2' })).to be(true)
    end

    it 'does NOT reauthorize and returns false when Evolution reports a closed/other state' do
      allow(job).to receive(:evolution_connection_state).and_return('close')
      expect(channel).not_to receive(:reauthorized!)
      expect(job.send(:reconcile_channel_state!, channel, {})).to be(false)
    end

    it 'returns false (skips) for non-evolution providers' do
      cloud = instance_double(Channel::Whatsapp, provider: 'whatsapp_cloud')
      allow(cloud).to receive(:is_a?).with(Channel::Whatsapp).and_return(true)
      expect(job.send(:reconcile_channel_state!, cloud, {})).to be(false)
    end

    it 'returns false when provider_config is incomplete' do
      bare = instance_double(Channel::Whatsapp, provider: 'evolution', provider_config: {})
      allow(bare).to receive(:is_a?).with(Channel::Whatsapp).and_return(true)
      expect(job.send(:reconcile_channel_state!, bare, {})).to be(false)
    end

    it 'is resilient: returns false if reconciliation raises' do
      allow(job).to receive(:evolution_connection_state).and_raise(StandardError)
      expect(job.send(:reconcile_channel_state!, channel, {})).to be(false)
    end
  end
end
