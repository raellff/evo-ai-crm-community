# Self-heal for environments bitten by the CRM/auth migration version collision
# (EVO-1911): CRM and auth shared version 20260622120000 in the same
# schema_migrations table, so databases that migrated auth first recorded the
# version before CRM's add_source_to_messages ran — Rails then skips it forever,
# leaving messages.source missing and breaking the Message model at boot
# ("Undeclared attribute type for enum 'source'").
#
# Re-applies the skipped column iff it is absent; no-op on healthy databases.
# Manual alternative for environments that cannot upgrade yet:
# scripts/README-migration-guard.md (umbrella repo), "Recovery" section.
class HealMessagesSourceAfterVersionCollision < ActiveRecord::Migration[7.1]
  def up
    return if column_exists?(:messages, :source)

    add_column :messages, :source, :integer, default: 0, null: false
  end

  def down
    # No-op: the column is owned by 20260622120000_add_source_to_messages.
    # Reverting the heal must not drop a column that migration still declares.
  end
end
