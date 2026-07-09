# frozen_string_literal: true

class AddAccountIdToLabels < ActiveRecord::Migration[7.1]
  def change
    add_reference :labels, :account, type: :uuid, foreign_key: true, index: true
    change_column_null :labels, :account_id, true
  end
end
