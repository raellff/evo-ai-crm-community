class AddCustomFieldsToPipelinesAndPipelineStages < ActiveRecord::Migration[7.1]
  def up
    # Add custom_fields to pipelines
    add_column :pipelines, :custom_fields, :jsonb, default: {}, null: false, if_not_exists: true
    add_index :pipelines, :custom_fields, using: :gin, if_not_exists: true

    # Add custom_fields to pipeline_stages
    add_column :pipeline_stages, :custom_fields, :jsonb, default: {}, null: false, if_not_exists: true
    add_index :pipeline_stages, :custom_fields, using: :gin, if_not_exists: true
  end

  def down
    remove_index :pipeline_stages, :custom_fields if index_exists?(:pipeline_stages, :custom_fields)
    remove_column :pipeline_stages, :custom_fields if column_exists?(:pipeline_stages, :custom_fields)

    remove_index :pipelines, :custom_fields if index_exists?(:pipelines, :custom_fields)
    remove_column :pipelines, :custom_fields if column_exists?(:pipelines, :custom_fields)
  end
end
