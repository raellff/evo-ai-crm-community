# frozen_string_literal: true

class AddAccountIdToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_reference :inboxes, :account, type: :uuid, foreign_key: true, index: true
    change_column_null :inboxes, :account_id, true
  end
end
