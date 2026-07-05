class AddConfigurationFieldsToAgentBotInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_bot_inboxes, :allowed_conversation_statuses, :jsonb, default: [], null: false, if_not_exists: true
    add_column :agent_bot_inboxes, :allowed_label_ids, :jsonb, default: [], null: false, if_not_exists: true

    add_index :agent_bot_inboxes, :allowed_conversation_statuses, using: :gin, if_not_exists: true
    add_index :agent_bot_inboxes, :allowed_label_ids, using: :gin, if_not_exists: true
  end
end

