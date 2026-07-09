# frozen_string_literal: true

# Multi-account support (see specs/multi-account-tenancy) replaces the old
# single-fixed-account model (RuntimeConfig('account') blob, never actually
# read by application code) with a real, per-request Account resolved from
# the auth-service and enforced via AccountScoped. This migration backfills
# installs that predate that change, so their existing data keeps working
# with zero manual steps: the pre-existing account becomes "Account #1" and
# every existing row on the 8 tenant-scoped tables is attached to it.
class BackfillAccountIdForExistingRecords < ActiveRecord::Migration[7.1]
  TABLES = %i[agent_bots contacts conversations inboxes labels messages teams users].freeze

  def up
    return if TABLES.none? { |table| table_has_null_account_id?(table) } # nothing to backfill

    account = Account.first || build_account_from_runtime_config_blob

    TABLES.each do |table|
      next unless table_has_null_account_id?(table)

      execute <<-SQL.squish
        UPDATE #{table} SET account_id = #{connection.quote(account.id)} WHERE account_id IS NULL
      SQL
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def table_has_null_account_id?(table)
    execute("SELECT 1 FROM #{table} WHERE account_id IS NULL LIMIT 1").ntuples.positive?
  end

  def build_account_from_runtime_config_blob
    data = RuntimeConfig.account || {}

    Account.create!(
      name: data['name'].presence || 'Evolution Community',
      subdomain: data['subdomain'].presence || data['id'] || SecureRandom.uuid,
      support_email: data['support_email'],
      locale: data['locale'].presence || 'pt-BR',
      status: data['status'].presence || 'active',
      settings: data['settings'] || {},
      custom_attributes: data['custom_attributes'] || {}
    )
  end
end
