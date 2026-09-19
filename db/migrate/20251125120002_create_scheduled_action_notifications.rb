# frozen_string_literal: true

class CreateScheduledActionNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :scheduled_action_notifications, if_not_exists: true do |t|
      t.bigint :scheduled_action_id, null: false
      t.uuid :user_id, null: false
      t.string :notification_type, null: false, limit: 20  # 'success', 'failure', 'retry'
      t.string :status, null: false, default: 'pending', limit: 20  # 'pending', 'sent', 'failed'
      t.text :message
      t.text :error_details

      t.timestamps
    end

    add_index :scheduled_action_notifications, :scheduled_action_id, if_not_exists: true
    add_index :scheduled_action_notifications, :user_id, if_not_exists: true
    add_index :scheduled_action_notifications, :notification_type, if_not_exists: true
    add_index :scheduled_action_notifications, :status, if_not_exists: true
    add_index :scheduled_action_notifications, [:user_id, :created_at], name: 'idx_notifications_user_date', if_not_exists: true
    add_index :scheduled_action_notifications, [:scheduled_action_id, :notification_type], name: 'idx_notifications_action_type', if_not_exists: true

    add_foreign_key :scheduled_action_notifications, :scheduled_actions, on_delete: :cascade, if_not_exists: true
  end
end
