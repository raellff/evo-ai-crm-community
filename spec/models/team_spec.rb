# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Team, type: :model do
  describe 'associations' do
    it { should belong_to(:account).optional(true) }
  end

  describe 'name casing preservation' do
    it 'preserves mixed-case name on create' do
      team = Team.create!(name: 'Marketing Team')
      expect(team.reload.name).to eq('Marketing Team')
    end

    it 'preserves uppercase name on create' do
      team = Team.create!(name: 'VIP SUPPORT')
      expect(team.reload.name).to eq('VIP SUPPORT')
    end

    it 'preserves mixed-case name on update' do
      team = Team.create!(name: 'old name')
      team.update!(name: 'New Team Name')
      expect(team.reload.name).to eq('New Team Name')
    end

    it 'strips whitespace but preserves casing' do
      team = Team.create!(name: '  Sales Team  ')
      expect(team.reload.name).to eq('Sales Team')
    end
  end

  describe 'case-insensitive uniqueness' do
    it 'rejects duplicate name with different casing' do
      Team.create!(name: 'Support')
      duplicate = Team.new(name: 'support')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to be_present
    end

    it 'allows same name in different contexts' do
      Team.create!(name: 'Support')
      team = Team.new(name: 'Support Team')
      expect(team).to be_valid
    end
  end
end
