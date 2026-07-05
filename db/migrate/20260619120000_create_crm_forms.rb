class CreateCrmForms < ActiveRecord::Migration[7.1]
  def change
    create_table :crm_forms, id: :uuid, if_not_exists: true do |t|
      t.string :name, null: false, limit: 255
      t.string :slug, null: false, limit: 255
      t.string :title, limit: 255
      t.text :description
      t.jsonb :appearance, null: false, default: {}
      t.jsonb :fields, null: false, default: []
      t.jsonb :routing_rules, null: false, default: []
      t.uuid :default_pipeline_id, null: false
      t.uuid :default_stage_id
      t.boolean :published, null: false, default: false

      t.timestamps
    end

    add_index :crm_forms, :slug, unique: true, if_not_exists: true
    add_index :crm_forms, :published, if_not_exists: true
    add_index :crm_forms, :fields, using: :gin, if_not_exists: true
    add_index :crm_forms, :routing_rules, using: :gin, if_not_exists: true

    add_foreign_key :crm_forms, :pipelines, column: :default_pipeline_id, if_not_exists: true
    add_foreign_key :crm_forms, :pipeline_stages, column: :default_stage_id, if_not_exists: true

    add_check_constraint :crm_forms, "name != ''", name: 'crm_forms_name_not_empty', if_not_exists: true
    add_check_constraint :crm_forms, "slug != ''", name: 'crm_forms_slug_not_empty', if_not_exists: true
  end
end
