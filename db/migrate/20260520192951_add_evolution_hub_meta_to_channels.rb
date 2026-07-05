# frozen_string_literal: true

# Adds JSONB columns on the Facebook Page and Instagram channel tables so the
# Evolution Hub integration can store its own bookkeeping (channel_id,
# channel_token, status, public_link) without colliding with the existing
# OAuth fields. WhatsApp Cloud already has a provider_config JSONB and uses
# the key `evolution_hub` inside it — no schema change needed there.
class AddEvolutionHubMetaToChannels < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_facebook_pages, :evolution_hub_meta, :jsonb, default: {}, null: false, if_not_exists: true
    add_column :channel_instagram, :evolution_hub_meta, :jsonb, default: {}, null: false, if_not_exists: true
  end
end
