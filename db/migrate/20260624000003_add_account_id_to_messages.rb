# frozen_string_literal: true

class AddAccountIdToMessages < ActiveRecord::Migration[7.1]
  def change
    add_reference :messages, :account, type: :uuid, foreign_key: true, index: true
    change_column_null :messages, :account_id, true
  end
end
