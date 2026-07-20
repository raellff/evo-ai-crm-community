# frozen_string_literal: true

# == Schema Information
#
# Table name: pipelines
#
#  id            :uuid             not null, primary key
#  created_by_id :uuid             not null
#  name          :string           not null
#  description   :text
#  pipeline_type :string           default("custom"), not null
#  visibility    :integer          default("private")
#  config        :jsonb
#  is_active     :boolean          default(TRUE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  custom_fields :jsonb            not null
#  is_default    :boolean          default(FALSE), not null
#  account_id    :uuid
#
require 'rails_helper'

RSpec.describe Pipeline, type: :model do
  let(:admin_user) { User.create!(email: 'admin@example.com', name: 'Admin User') }
  let(:account_owner) { User.create!(email: 'owner@example.com', name: 'Account Owner') }

  describe 'associations' do
    it { should belong_to(:account).optional(true) }
  end

  describe 'account isolation' do
    let(:account_a) { Account.create!(name: 'Account A', subdomain: "account-a-#{SecureRandom.hex(4)}") }
    let(:account_b) { Account.create!(name: 'Account B', subdomain: "account-b-#{SecureRandom.hex(4)}") }

    after { Current.reset }

    it 'only returns the current account\'s pipelines' do
      Current.account = account_a
      pipeline_a = described_class.create!(name: 'Pipeline A', pipeline_type: 'sales', created_by: admin_user)

      Current.account = account_b
      pipeline_b = described_class.create!(name: 'Pipeline A', pipeline_type: 'sales', created_by: admin_user)

      Current.account = account_a
      expect(described_class.all).to include(pipeline_a)
      expect(described_class.all).not_to include(pipeline_b)
      expect(described_class.find_by(id: pipeline_b.id)).to be_nil
    end

    it 'stamps new records with the current account' do
      Current.account = account_a
      pipeline = described_class.create!(name: 'Stamped Pipeline', pipeline_type: 'sales', created_by: admin_user)

      expect(pipeline.account_id).to eq(account_a.id)
    end

    it 'allows the same default pipeline flag in different accounts' do
      Current.account = account_a
      described_class.create!(name: 'Default A', pipeline_type: 'sales', is_default: true, created_by: admin_user)

      Current.account = account_b
      pipeline_b = described_class.new(name: 'Default B', pipeline_type: 'sales', is_default: true, created_by: admin_user)

      expect(pipeline_b).to be_valid
    end
  end

  describe 'VALID_TYPES' do
    it 'contains exactly the expected pipeline types' do
      expect(Pipeline::VALID_TYPES).to contain_exactly('sales', 'support', 'onboarding', 'custom', 'marketing')
    end

    it 'is frozen' do
      expect(Pipeline::VALID_TYPES).to be_frozen
    end

    it 'rejects pipeline_type outside VALID_TYPES' do
      pipeline = Pipeline.new(name: 'Bad', pipeline_type: 'lead', created_by: admin_user)
      expect(pipeline).not_to be_valid
      expect(pipeline.errors[:pipeline_type]).to be_present
    end
  end

  describe '.accessible_by' do
    let!(:default_private_pipeline) do
      described_class.create!(
        name: 'Default Pipeline',
        pipeline_type: 'sales',
        visibility: :private,
        is_default: true,
        created_by: admin_user
      )
    end

    let!(:private_pipeline) do
      described_class.create!(
        name: 'Admin Private Pipeline',
        pipeline_type: 'custom',
        visibility: :private,
        is_default: false,
        created_by: admin_user
      )
    end

    let!(:public_pipeline) do
      described_class.create!(
        name: 'Public Pipeline',
        pipeline_type: 'support',
        visibility: :public,
        is_default: false,
        created_by: admin_user
      )
    end

    let!(:owner_pipeline) do
      described_class.create!(
        name: 'Owner Pipeline',
        pipeline_type: 'custom',
        visibility: :private,
        is_default: false,
        created_by: account_owner
      )
    end

    context 'when queried by account owner (non-creator of default pipeline)' do
      subject(:accessible) { Pipeline.accessible_by(account_owner) }

      it 'includes default pipelines created by another user (AC1)' do
        expect(accessible).to include(default_private_pipeline)
      end

      it 'excludes private non-default pipelines from another user (AC2)' do
        expect(accessible).not_to include(private_pipeline)
      end

      it 'includes public pipelines (AC3)' do
        expect(accessible).to include(public_pipeline)
      end

      it 'includes own pipelines (AC4)' do
        expect(accessible).to include(owner_pipeline)
      end
    end

    context 'when queried by the creator (admin user)' do
      subject(:accessible) { Pipeline.accessible_by(admin_user) }

      it 'includes all own pipelines' do
        expect(accessible).to include(default_private_pipeline, private_pipeline, public_pipeline)
      end

      it 'excludes private pipelines from other users' do
        expect(accessible).not_to include(owner_pipeline)
      end
    end
  end
end
