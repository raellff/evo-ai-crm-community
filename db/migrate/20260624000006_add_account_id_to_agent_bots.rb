# frozen_string_literal: true

class AddAccountIdToAgentBots < ActiveRecord::Migration[7.1]
  def change
    add_reference :agent_bots, :account, type: :uuid, foreign_key: true, index: true
    change_column_null :agent_bots, :account_id, true
  end
end
