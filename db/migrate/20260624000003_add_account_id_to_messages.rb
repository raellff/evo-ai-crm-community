# frozen_string_literal: true

# Guarded: the auth service's schema.rb already carries account_id on the shared
# tables, so a fresh database must not fail here (and existing ones are no-ops).
class AddAccountIdToMessages < ActiveRecord::Migration[7.1]
  def up
    add_reference :messages, :account, type: :uuid, foreign_key: true, index: true unless column_exists?(:messages, :account_id)
    change_column_null :messages, :account_id, true
  end

  def down
    remove_reference :messages, :account, foreign_key: true, index: true if column_exists?(:messages, :account_id)
  end
end
