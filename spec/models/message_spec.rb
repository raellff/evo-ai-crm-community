# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message do
  include ActiveSupport::Testing::TimeHelpers

  describe 'associations' do
    it { should belong_to(:account).optional(true) }
  end

  describe '#refresh_conversation_activity!' do
    it 'uses current time when requested even if created_at is older' do
      conversation = double('Conversation', id: 'conv_1', class: Conversation)
      relation = double('Relation')
      message = described_class.new(created_at: 2.days.ago)
      allow(message).to receive(:conversation).and_return(conversation)

      travel_to(Time.zone.parse('2026-02-12 10:00:00')) do
        allow(Conversation).to receive(:where).with(id: 'conv_1').and_return(relation)
        expect(relation).to receive(:update_all).with(
          [
            'last_activity_at = GREATEST(COALESCE(last_activity_at, ?), ?), updated_at = ?',
            Time.current,
            Time.current,
            Time.current
          ]
        )

        message.refresh_conversation_activity!(message.created_at, use_current_time: true)
      end
    end

    it 'uses only provided timestamp when use_current_time is false' do
      older_time = Time.zone.parse('2026-02-10 10:00:00')
      conversation = double('Conversation', id: 'conv_2', class: Conversation)
      relation = double('Relation')
      message = described_class.new(created_at: older_time)
      allow(message).to receive(:conversation).and_return(conversation)

      travel_to(Time.zone.parse('2026-02-12 11:00:00')) do
        allow(Conversation).to receive(:where).with(id: 'conv_2').and_return(relation)
        expect(relation).to receive(:update_all).with(
          [
            'last_activity_at = GREATEST(COALESCE(last_activity_at, ?), ?), updated_at = ?',
            older_time,
            older_time,
            Time.current
          ]
        )

        message.refresh_conversation_activity!(message.created_at, use_current_time: false)
      end
    end
  end

  describe '#set_conversation_activity' do
    it 'delegates to refresh_conversation_activity! with current time' do
      conversation = double('Conversation', last_activity_at: nil)
      message = described_class.new(created_at: 1.day.ago)
      allow(message).to receive(:conversation).and_return(conversation)

      expect(message).to receive(:refresh_conversation_activity!).with(message.created_at, use_current_time: true)

      message.send(:set_conversation_activity)
    end
  end
end
