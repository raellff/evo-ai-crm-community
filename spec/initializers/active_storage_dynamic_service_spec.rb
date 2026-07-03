# frozen_string_literal: true

require 'rails_helper'

# EVO-1961: the dynamic service resolver must keep the CRM usable when a
# bucket-backed provider is selected but not fully configured. Instead of
# letting aws-sdk raise on every request (which is what makes self-hosted
# stacks unusable without S3), we fall back to :local and warn.
RSpec.describe 'ActiveStorage dynamic service resolver' do
  around do |example|
    original_service_env = ENV['ACTIVE_STORAGE_SERVICE']
    original_bucket_env = ENV['STORAGE_BUCKET_NAME']
    original_amazon_bucket_env = ENV['S3_BUCKET_NAME']
    example.run
  ensure
    ENV['ACTIVE_STORAGE_SERVICE'] = original_service_env
    ENV['STORAGE_BUCKET_NAME'] = original_bucket_env
    ENV['S3_BUCKET_NAME'] = original_amazon_bucket_env
  end

  before do
    allow(GlobalConfigService).to receive(:load) do |key, default|
      ENV.fetch(key.to_s, default)
    end
  end

  describe 'bucket-backed fallback (AC4)' do
    it 'falls back to :local when s3_compatible is selected but STORAGE_BUCKET_NAME is blank' do
      ENV['ACTIVE_STORAGE_SERVICE'] = 's3_compatible'
      ENV['STORAGE_BUCKET_NAME'] = ''

      expect(Rails.logger).to receive(:warn).with(/'s3_compatible' selected but bucket not configured/)
      expect(ActiveStorage::Blob.service).to eq(ActiveStorage::Blob.services.fetch(:local))
    end

    it 'falls back to :local when amazon is selected but S3_BUCKET_NAME is blank' do
      ENV['ACTIVE_STORAGE_SERVICE'] = 'amazon'
      ENV['S3_BUCKET_NAME'] = nil
      ENV['STORAGE_BUCKET_NAME'] = nil

      expect(Rails.logger).to receive(:warn).with(/'amazon' selected but bucket not configured/)
      expect(ActiveStorage::Blob.service).to eq(ActiveStorage::Blob.services.fetch(:local))
    end

    it 'keeps s3_compatible when bucket is configured (does not fall back)' do
      ENV['ACTIVE_STORAGE_SERVICE'] = 's3_compatible'
      ENV['STORAGE_BUCKET_NAME'] = 'my-bucket'

      # Stub the registry so we don't lazy-build a real S3 client at test time.
      fake_s3 = instance_double(ActiveStorage::Service, name: :s3_compatible)
      allow(ActiveStorage::Blob.services).to receive(:fetch).with(:s3_compatible).and_return(fake_s3)

      expect(Rails.logger).not_to receive(:warn).with(/bucket not configured/)
      expect(ActiveStorage::Blob.service.name).to eq(:s3_compatible)
    end
  end

  describe ':local as the default (AC1)' do
    it 'resolves :local when ACTIVE_STORAGE_SERVICE is unset' do
      ENV['ACTIVE_STORAGE_SERVICE'] = nil

      expect(ActiveStorage::Blob.service).to eq(ActiveStorage::Blob.services.fetch(:local))
    end
  end
end
