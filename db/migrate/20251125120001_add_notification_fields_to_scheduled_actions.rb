# frozen_string_literal: true

class AddNotificationFieldsToScheduledActions < ActiveRecord::Migration[7.0]
  def change
    add_column :scheduled_actions, :notify_user_id, :uuid, if_not_exists: true
    add_column :scheduled_actions, :notification_sent_at, :datetime, if_not_exists: true

    add_index :scheduled_actions, :notify_user_id, if_not_exists: true
  end
end
