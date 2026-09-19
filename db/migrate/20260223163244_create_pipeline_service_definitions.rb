class CreatePipelineServiceDefinitions < ActiveRecord::Migration[7.1]
  def change
    create_table :pipeline_service_definitions, id: :uuid, if_not_exists: true do |t|
      t.references :pipeline, type: :uuid, null: false, foreign_key: true
      t.string :name, null: false, limit: 255
      t.decimal :default_value, precision: 10, scale: 2, null: false, default: 0.0
      t.string :currency, limit: 3, default: 'BRL'
      t.text :description

      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :pipeline_service_definitions, [:pipeline_id, :name], unique: true, name: 'index_pipeline_service_definitions_on_pipeline_and_name', if_not_exists: true
    add_index :pipeline_service_definitions, :active, if_not_exists: true
  end
end
