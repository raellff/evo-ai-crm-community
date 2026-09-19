class AddFacebookInteractionTypeAndAllowedPostsToAgentBotInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_bot_inboxes, :facebook_interaction_type, :string, default: 'both', null: false, if_not_exists: true
    add_column :agent_bot_inboxes, :facebook_allowed_post_ids, :jsonb, default: [], null: false, if_not_exists: true

    add_index :agent_bot_inboxes, :facebook_interaction_type, if_not_exists: true
    add_index :agent_bot_inboxes, :facebook_allowed_post_ids, using: :gin, if_not_exists: true
  end
end

