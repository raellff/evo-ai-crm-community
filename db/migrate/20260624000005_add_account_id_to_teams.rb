# frozen_string_literal: true

class AddAccountIdToTeams < ActiveRecord::Migration[7.1]
  def change
    add_reference :teams, :account, type: :uuid, foreign_key: true, index: true
    change_column_null :teams, :account_id, true
  end
end
