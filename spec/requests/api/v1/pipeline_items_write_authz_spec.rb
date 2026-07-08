# frozen_string_literal: true

require 'rails_helper'

# Pipeline item mutating actions authorize against the pipeline WRITE policy
# (PipelinePolicy#update?), while reads stay at #view?. Previously every action
# — including create/update/destroy — authorized only #view? (a read-level
# check) on the parent pipeline. These specs prove the split: a caller allowed
# to view but not update the pipeline can list items but cannot create one.
RSpec.describe 'Pipeline item write-level authorization', type: :request do
  let(:user) { User.create!(name: 'Perm Probe', email: "probe-#{SecureRandom.hex(4)}@example.com") }
  let(:pipeline) { Pipeline.create!(name: 'Sales', pipeline_type: 'sales', created_by: user) }

  before do
    probe = user
    allow_any_instance_of(Api::BaseController).to receive(:authenticate_request!) do
      Current.user = probe
      Current.evo_permission_cache ||= {}
    end
    # View is permitted, write is not: isolates the read-vs-write policy level.
    allow_any_instance_of(PipelinePolicy).to receive(:view?).and_return(true)
    allow_any_instance_of(PipelinePolicy).to receive(:update?).and_return(false)
  end

  after { Current.reset }

  it 'allows listing items with only view-level access' do
    get "/api/v1/pipelines/#{pipeline.id}/pipeline_items", as: :json

    expect(response).to have_http_status(:ok)
  end

  it 'denies creating an item without write-level access' do
    expect do
      post "/api/v1/pipelines/#{pipeline.id}/pipeline_items",
           params: { pipeline_item: { entity_type: 'lead' } }, as: :json
    end.not_to change(PipelineItem, :count)

    expect(response).to have_http_status(:unauthorized)
  end
end
