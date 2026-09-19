class AddFacebookCommentConfigToAgentBotInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_bot_inboxes, :facebook_comment_replies_enabled, :boolean, default: false, null: false, if_not_exists: true
    add_column :agent_bot_inboxes, :facebook_comment_agent_bot_id, :uuid, null: true, if_not_exists: true

    add_index :agent_bot_inboxes, :facebook_comment_agent_bot_id, if_not_exists: true
    add_foreign_key :agent_bot_inboxes, :agent_bots, column: :facebook_comment_agent_bot_id, on_delete: :nullify, if_not_exists: true
  end
end

