# frozen_string_literal: true

class AddContactToPipelineConversations < ActiveRecord::Migration[7.1]
  def change
    # Add contact_id column to support leads without conversations
    add_column :pipeline_conversations, :contact_id, :uuid, if_not_exists: true
    add_index :pipeline_conversations, :contact_id, if_not_exists: true

    # Make conversation_id optional (allow NULL)
    change_column_null :pipeline_conversations, :conversation_id, true

    # Remove existing unique index
    remove_index :pipeline_conversations, name: 'index_pipeline_conversations_on_conversation_id_and_pipeline_id'

    # Add conditional unique index for conversation-based pipeline (deals)
    add_index :pipeline_conversations, [:conversation_id, :pipeline_id],
              unique: true,
              name: 'index_pipeline_conversations_on_conversation_id_and_pipeline_id',
              where: 'conversation_id IS NOT NULL',
              if_not_exists: true

    # Add conditional unique index for contact-based pipeline (leads)
    add_index :pipeline_conversations, [:contact_id, :pipeline_id],
              unique: true,
              name: 'index_pipeline_conversations_on_contact_id_and_pipeline_id',
              where: 'conversation_id IS NULL',
              if_not_exists: true

    # Add foreign key constraint
    add_foreign_key :pipeline_conversations, :contacts, column: :contact_id, if_not_exists: true
  end
end

