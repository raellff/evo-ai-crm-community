# frozen_string_literal: true

class RemoveSlaSystem < ActiveRecord::Migration[7.0]
  def up
    # Remove foreign key constraints first
    if foreign_key_exists?(:conversations, :sla_policies)
      remove_foreign_key :conversations, :sla_policies, if_exists: true
    end

    if foreign_key_exists?(:sla_events, :sla_policies)
      remove_foreign_key :sla_events, :sla_policies, if_exists: true
    end

    if foreign_key_exists?(:sla_events, :applied_slas)
      remove_foreign_key :sla_events, :applied_slas, if_exists: true
    end

    if foreign_key_exists?(:sla_events, :conversations)
      remove_foreign_key :sla_events, :conversations, if_exists: true
    end

    if foreign_key_exists?(:applied_slas, :sla_policies)
      remove_foreign_key :applied_slas, :sla_policies, if_exists: true
    end

    if foreign_key_exists?(:applied_slas, :conversations)
      remove_foreign_key :applied_slas, :conversations, if_exists: true
    end

    # Remove indexes
    remove_index :conversations, :sla_policy_id if index_exists?(:conversations, :sla_policy_id)
    remove_index :sla_events, :applied_sla_id if index_exists?(:sla_events, :applied_sla_id)
    remove_index :sla_events, :conversation_id if index_exists?(:sla_events, :conversation_id)
    remove_index :sla_events, :event_type if index_exists?(:sla_events, :event_type)
    remove_index :sla_events, :sla_policy_id if index_exists?(:sla_events, :sla_policy_id)
    remove_index :applied_slas, :conversation_id if index_exists?(:applied_slas, :conversation_id)
    remove_index :applied_slas, :sla_policy_id if index_exists?(:applied_slas, :sla_policy_id)
    # Drop tables
    drop_table :sla_events, if_exists: true if table_exists?(:sla_events)
    drop_table :applied_slas, if_exists: true if table_exists?(:applied_slas)
    drop_table :sla_policies, if_exists: true if table_exists?(:sla_policies)

    # Remove column from conversations table
    remove_column :conversations, :sla_policy_id, :uuid, if_exists: true if column_exists?(:conversations, :sla_policy_id)
  end

  def down
    # Recreate tables (for rollback purposes)
    create_table :sla_policies, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :first_response_time_enabled, default: false
      t.integer :first_response_time_threshold
      t.boolean :next_response_time_enabled, default: false
      t.integer :next_response_time_threshold
      t.boolean :resolution_time_enabled, default: false
      t.integer :resolution_time_threshold
      t.boolean :only_during_business_hours, default: false
      t.timestamps
    end

    create_table :applied_slas, id: :uuid do |t|
      t.uuid :sla_policy_id, null: false
      t.uuid :conversation_id, null: false
      t.timestamps

      t.index [:sla_policy_id, :conversation_id], unique: true, name: 'index_applied_slas_on_sla_policy_conversation'
      t.index :conversation_id
      t.index :sla_policy_id

      t.foreign_key :sla_policies
      t.foreign_key :conversations
    end

    create_table :sla_events, id: :uuid do |t|
      t.uuid :sla_policy_id, null: false
      t.uuid :applied_sla_id, null: false
      t.uuid :conversation_id, null: false
      t.string :event_type, null: false
      t.jsonb :meta, default: {}
      t.timestamps

      t.index :applied_sla_id
      t.index :conversation_id
      t.index :event_type
      t.index :sla_policy_id

      t.foreign_key :sla_policies
      t.foreign_key :applied_slas
      t.foreign_key :conversations
    end

    # Add column back to conversations
    add_column :conversations, :sla_policy_id, :uuid unless column_exists?(:conversations, :sla_policy_id)
    add_foreign_key :conversations, :sla_policies unless foreign_key_exists?(:conversations, :sla_policies)
    add_index :conversations, :sla_policy_id unless index_exists?(:conversations, :sla_policy_id)
  end
end

