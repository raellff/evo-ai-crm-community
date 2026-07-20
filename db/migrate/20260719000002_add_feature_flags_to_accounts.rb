# frozen_string_literal: true

# See specs/account-feature-toggles/. Revives the dormant Featurable/
# flag_shih_tzu mechanism (app/models/concerns/featurable.rb) by finally
# giving Account the bitmask column it was written for. `default: 0` (every
# bit off) is only a schema-level fallback for stray inserts - the real
# "which features are on by default" logic lives in resolve_account
# (evo_auth_concern.rb), which stamps features.yml's defaults onto every
# newly-synced Account before persisting it. Pre-existing accounts are
# backfilled by the next migration, not by this one.
class AddFeatureFlagsToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :feature_flags, :bigint, default: 0, null: false
  end
end
