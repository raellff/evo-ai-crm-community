# frozen_string_literal: true

# See db/migrate/20260719000002_add_feature_flags_to_accounts.rb. That
# migration's column default (0 - every feature off) only covers stray
# inserts; existing Accounts need their bitmask actually populated with
# features.yml's declared defaults, or every feature would silently appear
# "off" for them the moment feature gates are added (PRD acceptance
# criterion #8: this rollout must be behavior-neutral for existing accounts).
#
# Only turns bits ON (never off), so this is safe to think of as additive
# and is idempotent - running it again is a no-op.
class BackfillFeatureFlagsForExistingAccounts < ActiveRecord::Migration[7.1]
  def up
    return unless ActiveRecord::Base.connection.table_exists?(:accounts)

    default_enabled_names = Featurable::FEATURE_LIST.select { |f| f['enabled'] }.pluck('name')
    return if default_enabled_names.empty?

    Account.find_each do |account|
      account.enable_features(*default_enabled_names)
      account.save!(validate: false)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
