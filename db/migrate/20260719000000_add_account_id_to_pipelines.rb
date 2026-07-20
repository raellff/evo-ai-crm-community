# frozen_string_literal: true

class AddAccountIdToPipelines < ActiveRecord::Migration[7.1]
  def change
    add_reference :pipelines, :account, type: :uuid, foreign_key: true, index: true

    # Global unique name -> unique per account
    remove_index :pipelines, name: 'index_pipelines_on_name' if index_exists?(:pipelines, :name, name: 'index_pipelines_on_name')
    add_index :pipelines, [:account_id, :name], unique: true

    # Global "one default pipeline" -> one default pipeline per account
    if index_exists?(:pipelines, :is_default, name: 'index_pipelines_on_is_default_unique')
      remove_index :pipelines, name: 'index_pipelines_on_is_default_unique'
    end
    add_index :pipelines, [:account_id, :is_default], unique: true, where: 'is_default = true',
                                                        name: 'index_pipelines_on_account_id_and_is_default_unique'

    change_column_null :pipelines, :account_id, true
  end
end
