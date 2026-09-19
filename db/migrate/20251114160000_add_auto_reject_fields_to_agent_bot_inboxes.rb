class AddAutoRejectFieldsToAgentBotInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_bot_inboxes, :auto_reject_explicit_words, :boolean, default: false, null: false, if_not_exists: true
    add_column :agent_bot_inboxes, :auto_reject_offensive_sentiment, :boolean, default: false, null: false, if_not_exists: true

    add_index :agent_bot_inboxes, :auto_reject_explicit_words, if_not_exists: true
    add_index :agent_bot_inboxes, :auto_reject_offensive_sentiment, if_not_exists: true
  end
end

