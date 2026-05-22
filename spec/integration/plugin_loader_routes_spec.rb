# frozen_string_literal: true

require 'rails_helper'

# Proves the host side of the plugin_loader routes contract end-to-end: a
# plugin registered through EvoExtensionPoints::PluginLoader has its `routes`
# callback drawn onto the real application router by the `draw_routes(self)`
# call in config/routes.rb, and the contributed route becomes reachable.
RSpec.describe 'plugin_loader routes integration', type: :request do
  after do
    EvoExtensionPoints::PluginLoader.reset!
    Rails.application.reload_routes!
  end

  it 'does not contribute any route when no plugin is registered' do
    Rails.application.reload_routes!
    get '/__plugin_loader_probe'
    expect(response).to have_http_status(:not_found)
  end

  it 'mounts a route contributed by a registered plugin after reload' do
    EvoExtensionPoints::PluginLoader.register_plugin(:probe) do |plugin|
      plugin.routes do |mapper|
        mapper.get '/__plugin_loader_probe',
                   to: ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['probe-ok']] }
      end
    end
    Rails.application.reload_routes!

    get '/__plugin_loader_probe'
    expect(response).to have_http_status(:ok)
    expect(response.body).to eq('probe-ok')
  end
end
