# frozen_string_literal: true

require 'rails_helper'

# Unit-level coverage for FeatureGateConcern, exercised directly via an
# anonymous host class (same idiom as spec/controllers/concerns/label_concern_spec.rb),
# since the mechanism itself (not any one controller's routing) is what
# needs to be correct - see specs/account-feature-toggles Step 3.
# End-to-end coverage against a real, routed controller lives in
# spec/requests/api/v1/feature_gate_spec.rb (PipelinesController).
RSpec.describe FeatureGateConcern, type: :concern do
  let(:host_class) do
    Class.new do
      include FeatureGateConcern

      attr_accessor :last_error

      public :check_feature_enabled!

      def error_response(code, _message, status:)
        self.last_error = { code: code, status: status }
      end
    end
  end

  let(:host) { host_class.new }
  let(:account) { Account.create!(name: 'Acme', subdomain: "acme-#{SecureRandom.hex(4)}") }

  after { Current.reset }

  describe '.require_feature' do
    it 'raises at load time for a name not present in config/features.yml' do
      expect do
        Class.new do
          include FeatureGateConcern
          require_feature :not_a_real_feature
        end
      end.to raise_error(ArgumentError, /Unknown feature/)
    end
  end

  describe '#check_feature_enabled!' do
    it 'renders FEATURE_NOT_AVAILABLE when the account has the feature disabled' do
      account.disable_features!(:pipelines)
      Current.account = account

      host.check_feature_enabled!(:pipelines)

      expect(host.last_error).to eq(code: ApiErrorCodes::FEATURE_NOT_AVAILABLE, status: :forbidden)
    end

    it 'does not render an error when the account has the feature enabled' do
      account.enable_features!(:pipelines)
      Current.account = account

      host.check_feature_enabled!(:pipelines)

      expect(host.last_error).to be_nil
    end

    it 'renders FEATURE_NOT_AVAILABLE when there is no current Account' do
      Current.account = nil

      host.check_feature_enabled!(:pipelines)

      expect(host.last_error).to eq(code: ApiErrorCodes::FEATURE_NOT_AVAILABLE, status: :forbidden)
    end

    it 'bypasses the gate for service-authenticated (internal) callers' do
      Current.account = nil
      Current.service_authenticated = true

      host.check_feature_enabled!(:pipelines)

      expect(host.last_error).to be_nil
    end

    it 'never lets one Account\'s disabled feature affect another Account' do
      account.disable_features!(:pipelines)
      other_account = Account.create!(name: 'Other', subdomain: "other-#{SecureRandom.hex(4)}")
      other_account.enable_features!(:pipelines) # simulates resolve_account's default-application

      Current.account = other_account
      host.check_feature_enabled!(:pipelines)

      expect(host.last_error).to be_nil
    end
  end
end
