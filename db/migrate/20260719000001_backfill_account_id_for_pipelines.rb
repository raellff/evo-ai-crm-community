# frozen_string_literal: true

# See specs/account-feature-toggles/03-plan.md, Fase 0a. Pipelines predate
# AccountScoped and were global; this backfills pre-existing rows onto
# Account #1, mirroring db/migrate/20260706000000_backfill_account_id_for_existing_records.rb
# for the original AccountScoped rollout.
class BackfillAccountIdForPipelines < ActiveRecord::Migration[7.1]
  def up
    return unless execute('SELECT 1 FROM pipelines WHERE account_id IS NULL LIMIT 1').ntuples.positive?

    account = Account.first
    return if account.nil? # no account to backfill onto yet (fresh/empty install)

    execute <<-SQL.squish
      UPDATE pipelines SET account_id = #{connection.quote(account.id)} WHERE account_id IS NULL
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
