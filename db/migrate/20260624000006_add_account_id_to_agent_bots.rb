# frozen_string_literal: true

# Guarded: the shared schema may already carry account_id (see the other
# add_account_id_to_* migrations), so a fresh database must not fail here.
class AddAccountIdToAgentBots < ActiveRecord::Migration[7.1]
  def up
    add_reference :agent_bots, :account, type: :uuid, foreign_key: true, index: true unless column_exists?(:agent_bots, :account_id)
    change_column_null :agent_bots, :account_id, true
  end

  def down
    remove_reference :agent_bots, :account, foreign_key: true, index: true if column_exists?(:agent_bots, :account_id)
  end
end
