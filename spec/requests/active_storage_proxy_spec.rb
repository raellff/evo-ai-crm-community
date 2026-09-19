# frozen_string_literal: true

# Integration coverage for ActiveStorage proxy delivery (EVO-2006): the app
# must serve the blob bytes itself so the storage endpoint can stay private.
# Also exercises the test-environment parity with dev/staging/production
# (resolve_model_to_route defaults to :rails_storage_proxy in all of them).

require 'rails_helper'

RSpec.describe 'ActiveStorage proxy delivery', type: :request do
  let(:content) { 'proxied-file-bytes' }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(content),
      filename: 'attachment.txt',
      content_type: 'text/plain'
    )
  end

  it 'serves the blob bytes through the app on the browser-facing proxy URL' do
    get rails_storage_proxy_path(blob)

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq(content)
    expect(response.headers['Content-Type']).to include('text/plain')
  end

  describe 'outbound URLs with expiring signed ids (Evolution API / Go)' do
    let(:expiring_path) do
      rails_service_blob_proxy_path(blob.signed_id(expires_in: 15.minutes), blob.filename)
    end

    it 'serves the file while the signed id is valid' do
      get expiring_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(content)
    end

    it 'returns 404 once the 15-minute TTL has elapsed' do
      # Force the memoized path (and its signed id) to be generated NOW,
      # before the clock moves — inside the travel block it would be signed
      # at t+16min and still be valid.
      path = expiring_path

      travel(16.minutes) do
        get path
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
