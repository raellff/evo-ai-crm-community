# frozen_string_literal: true

begin
  require 'rails_helper'
rescue LoadError
  RSpec.describe 'Whatsapp::BaileysHandlers::MessagesUpdate' do
    it 'has spec scaffold ready' do
      skip 'rails_helper is not available in this workspace snapshot'
    end
  end
end

return unless defined?(Rails)

RSpec.describe Whatsapp::BaileysHandlers::MessagesUpdate do
  let(:host_class) do
    Class.new do
      include Whatsapp::BaileysHandlers::MessagesUpdate
    end
  end

  subject(:host) { host_class.new }
  let(:status_service) { instance_double(Messages::StatusUpdateService, perform: true) }

  before { allow(host).to receive(:incoming?).and_return(false) }

  describe '#update_status' do
    it 'rejects delivered→sent without invoking the service' do
      message = instance_double(Message, status: 'delivered', delivered?: true, read?: false)
      host.instance_variable_set(:@message, message)
      host.instance_variable_set(:@raw_message, { update: { status: 2 } })

      expect(Messages::StatusUpdateService).not_to receive(:new)
      host.send(:update_status)
    end

    it 'rejects any transition from read (read is final)' do
      message = instance_double(Message, status: 'read', read?: true, delivered?: false)
      host.instance_variable_set(:@message, message)
      host.instance_variable_set(:@raw_message, { update: { status: 0 } }) # ERROR → failed

      expect(Messages::StatusUpdateService).not_to receive(:new)
      host.send(:update_status)
    end

    it 'delegates sent→delivered to the service' do
      message = instance_double(Message, status: 'sent', delivered?: false, read?: false)
      host.instance_variable_set(:@message, message)
      host.instance_variable_set(:@raw_message, { update: { status: 3 } })

      expect(Messages::StatusUpdateService).to receive(:new).with(message, 'delivered').and_return(status_service)
      host.send(:update_status)
    end

    it 'delegates read to the service for an incoming message' do
      message = instance_double(Message, status: 'delivered', delivered?: false, read?: false)
      host.instance_variable_set(:@message, message)
      host.instance_variable_set(:@raw_message, { update: { status: 4 } })
      allow(host).to receive_messages(incoming?: true, update_last_seen_at: nil)

      expect(Messages::StatusUpdateService).to receive(:new).with(message, 'read').and_return(status_service)
      host.send(:update_status)
    end
  end
end
