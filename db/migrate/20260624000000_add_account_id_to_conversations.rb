# frozen_string_literal: true

class AddAccountIdToConversations < ActiveRecord::Migration[7.1]
  def change
    add_reference :conversations, :account, type: :uuid, foreign_key: true, index: true
    change_column_null :conversations, :account_id, true
  end
end
