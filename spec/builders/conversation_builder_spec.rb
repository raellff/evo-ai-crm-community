# frozen_string_literal: true

require 'rails_helper'

# EVO-1898 (D9) — regression coverage for `ConversationBuilder`.
#
# `POST /api/v1/conversations` was returning 500 with:
#   "private method 'status_explicitly_set!' called for an instance of Conversation"
#
# `Conversation#status_explicitly_set!` lived below the model's `private`
# marker, so the builder's external call `conversation.status_explicitly_set!`
# raised NoMethodError and rolled the creation transaction back.
#
# The method is part of the model's public collaborator API (it is invoked by
# builders and services to opt out of the inbox default status), so it must be
# public.
RSpec.describe ConversationBuilder do
  let(:channel) { Channel::WebWidget.create!(website_url: 'https://cbuilder.example.com') }
  let(:inbox) { Inbox.create!(name: 'CB Inbox', channel: channel) }
  let(:contact) { Contact.create!(name: 'Lead', email: "lead-#{SecureRandom.hex(4)}@test.com") }
  let(:contact_inbox) { ContactInbox.create!(contact: contact, inbox: inbox, source_id: SecureRandom.hex(4)) }

  describe 'Conversation#status_explicitly_set! visibility' do
    it 'is a public method so external collaborators can call it' do
      expect(Conversation.new).to respond_to(:status_explicitly_set!)
      expect(Conversation.public_instance_methods).to include(:status_explicitly_set!)
    end
  end

  describe '#perform with an explicit status (D9 reproduction)' do
    let(:params) { ActionController::Parameters.new(status: 'pending') }

    it 'creates the conversation without raising NoMethodError' do
      expect do
        described_class.new(params: params, contact_inbox: contact_inbox).perform
      end.to change(Conversation, :count).by(1)
    end

    it 'honours the explicitly provided status instead of the inbox default' do
      conversation = described_class.new(params: params, contact_inbox: contact_inbox).perform
      expect(conversation.status).to eq('pending')
    end
  end

  describe '#perform without an explicit status' do
    let(:params) { ActionController::Parameters.new({}) }

    it 'creates the conversation and lets the inbox default apply' do
      expect do
        described_class.new(params: params, contact_inbox: contact_inbox).perform
      end.to change(Conversation, :count).by(1)
    end
  end
end
