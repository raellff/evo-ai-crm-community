class AddSourceToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :source, :integer, default: 0, null: false, if_not_exists: true
  end
end
