# frozen_string_literal: true

begin
  require 'rails_helper'
rescue LoadError
  RSpec.describe 'Whatsapp::IncomingMessageBaseService' do
    it 'has spec scaffold ready' do
      skip 'rails_helper is not available in this workspace snapshot'
    end
  end
end

return unless defined?(Rails)

RSpec.describe Whatsapp::IncomingMessageBaseService do
  let(:host_class) do
    Class.new(Whatsapp::IncomingMessageBaseService) do
      attr_writer :processed_params

      def processed_params
        @processed_params
      end
    end
  end

  let(:message) do
    instance_double(
      Message,
      id: 1,
      status: 'sent',
      content_attributes: {},
      conversation: nil
    )
  end
  let(:inbox) { instance_double(Inbox) }
  let(:service) { host_class.new(inbox: inbox, params: {}) }
  let(:status_service) { instance_double(Messages::StatusUpdateService, perform: true) }

  describe '#update_message_with_status' do
    context 'when status is delivered' do
      it 'delegates to Messages::StatusUpdateService with nil external_error' do
        expect(Messages::StatusUpdateService).to receive(:new).with(message, 'delivered', nil).and_return(status_service)
        expect(status_service).to receive(:perform)

        service.send(:update_message_with_status, message, { status: 'delivered', id: 'wamid.xxx' })
      end
    end

    context 'when status is read' do
      it 'delegates with read + nil external_error' do
        expect(Messages::StatusUpdateService).to receive(:new).with(message, 'read', nil).and_return(status_service)

        service.send(:update_message_with_status, message, { status: 'read', id: 'wamid.xxx' })
      end
    end

    context 'when status is failed with errors[]' do
      let(:status_payload) do
        {
          status: 'failed',
          id: 'wamid.xxx',
          errors: [{ code: 131_026, title: 'Message undeliverable' }]
        }
      end

      it 'formats external_error as "<code>: <title>"' do
        expect(Messages::StatusUpdateService).to receive(:new)
          .with(message, 'failed', '131026: Message undeliverable')
          .and_return(status_service)

        service.send(:update_message_with_status, message, status_payload)
      end
    end

    context 'when status is failed but errors[] is absent' do
      it 'leaves external_error as nil' do
        expect(Messages::StatusUpdateService).to receive(:new).with(message, 'failed', nil).and_return(status_service)

        service.send(:update_message_with_status, message, { status: 'failed', id: 'wamid.xxx' })
      end
    end
  end
end
