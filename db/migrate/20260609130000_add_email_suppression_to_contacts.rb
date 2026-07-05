# frozen_string_literal: true

class AddEmailSuppressionToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :email_suppressed, :boolean, default: false, null: false, if_not_exists: true
    add_column :contacts, :email_suppression_reason, :string, if_not_exists: true
  end
end
