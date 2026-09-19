class CreateMessageTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :message_templates, id: :uuid, if_not_exists: true do |t|
      t.references :channel, polymorphic: true, null: false, type: :uuid, index: true
      
      t.string :name, null: false
      t.text :content, null: false
      t.string :language, default: 'pt_BR'
      t.string :category
      
      t.string :template_type
      
      t.jsonb :components, default: {}
      
      t.jsonb :variables, default: []
      
      t.string :media_url
      t.string :media_type
      
      t.jsonb :settings, default: {}
      t.jsonb :metadata, default: {}
      
      t.boolean :active, default: true
      
      t.timestamps
      
      t.index [:channel_type, :channel_id, :active], name: 'idx_templates_active_by_channel'
      t.index :name, name: 'idx_templates_by_name'
      t.index :category, name: 'idx_templates_by_category'
      t.index :template_type, name: 'idx_templates_by_type'
      t.index [:name, :channel_type, :channel_id], name: 'idx_templates_lookup'
    end
  end
end
