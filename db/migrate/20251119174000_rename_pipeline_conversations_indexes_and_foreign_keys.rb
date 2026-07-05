# frozen_string_literal: true

class RenamePipelineConversationsIndexesAndForeignKeys < ActiveRecord::Migration[7.1]
  def change
    # Renomear índices restantes em pipeline_items
    if index_exists?(:pipeline_items, :custom_fields, name: 'index_pipeline_conversations_on_custom_fields')
      rename_index :pipeline_items, 'index_pipeline_conversations_on_custom_fields', 'index_pipeline_items_on_custom_fields'
    end

    if index_exists?(:pipeline_items, :pipeline_id, name: 'index_pipeline_conversations_on_pipeline_id')
      rename_index :pipeline_items, 'index_pipeline_conversations_on_pipeline_id', 'index_pipeline_items_on_pipeline_id'
    end

    if index_exists?(:pipeline_items, :pipeline_stage_id, name: 'index_pipeline_conversations_on_pipeline_stage_id')
      rename_index :pipeline_items, 'index_pipeline_conversations_on_pipeline_stage_id', 'index_pipeline_items_on_pipeline_stage_id'
    end

    # Renomear índice em stage_movements
    if index_exists?(:stage_movements, :pipeline_conversation_id, name: 'index_stage_movements_on_pipeline_conversation_id')
      rename_index :stage_movements, 'index_stage_movements_on_pipeline_conversation_id', 'index_stage_movements_on_pipeline_item_id'
    end

    # Remover foreign keys antigas
    if foreign_key_exists?(:pipeline_items, name: 'fk_rails_pipeline_conversations_conversations')
      remove_foreign_key :pipeline_items, name: 'fk_rails_pipeline_conversations_conversations', if_exists: true
    elsif foreign_key_exists?(:pipeline_items, :conversations)
      remove_foreign_key :pipeline_items, :conversations, if_exists: true
    end

    if foreign_key_exists?(:pipeline_items, name: 'fk_rails_pipeline_conversations_pipeline_stages')
      remove_foreign_key :pipeline_items, name: 'fk_rails_pipeline_conversations_pipeline_stages', if_exists: true
    elsif foreign_key_exists?(:pipeline_items, :pipeline_stages)
      remove_foreign_key :pipeline_items, :pipeline_stages, if_exists: true
    end

    if foreign_key_exists?(:pipeline_items, name: 'fk_rails_pipeline_conversations_pipelines')
      remove_foreign_key :pipeline_items, name: 'fk_rails_pipeline_conversations_pipelines', if_exists: true
    elsif foreign_key_exists?(:pipeline_items, :pipelines)
      remove_foreign_key :pipeline_items, :pipelines, if_exists: true
    end

    if foreign_key_exists?(:stage_movements, name: 'fk_rails_stage_movements_pipeline_conversations')
      remove_foreign_key :stage_movements, name: 'fk_rails_stage_movements_pipeline_conversations', if_exists: true
    elsif foreign_key_exists?(:stage_movements, column: :pipeline_conversation_id)
      remove_foreign_key :stage_movements, column: :pipeline_conversation_id, if_exists: true
    end

    # Adicionar foreign keys com novo nome
    add_foreign_key :pipeline_items, :conversations, column: :conversation_id, if_not_exists: true unless foreign_key_exists?(:pipeline_items, :conversations)
    add_foreign_key :pipeline_items, :pipeline_stages, column: :pipeline_stage_id, if_not_exists: true unless foreign_key_exists?(:pipeline_items, :pipeline_stages)
    add_foreign_key :pipeline_items, :pipelines, column: :pipeline_id, if_not_exists: true unless foreign_key_exists?(:pipeline_items, :pipelines)
    add_foreign_key :pipeline_items, :contacts, column: :contact_id, if_not_exists: true unless foreign_key_exists?(:pipeline_items, :contacts)
    add_foreign_key :stage_movements, :pipeline_items, column: :pipeline_item_id, if_not_exists: true unless foreign_key_exists?(:stage_movements, :pipeline_items)
  end
end
