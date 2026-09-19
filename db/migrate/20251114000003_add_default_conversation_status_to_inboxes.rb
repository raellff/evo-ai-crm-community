class AddDefaultConversationStatusToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :default_conversation_status, :string, default: nil, null: true, if_not_exists: true
    add_index :inboxes, :default_conversation_status, if_not_exists: true
  end
end

