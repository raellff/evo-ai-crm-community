class CreateContactCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :contact_companies, id: :uuid, if_not_exists: true do |t|
      t.uuid :contact_id, null: false
      t.uuid :company_id, null: false

      t.timestamps
      t.datetime :deleted_at
    end
    
    # Foreign keys
    add_foreign_key :contact_companies, :contacts, column: :contact_id, if_not_exists: true
    add_foreign_key :contact_companies, :contacts, column: :company_id, if_not_exists: true
    # Índices para performance e unicidade
    add_index :contact_companies, [:contact_id, :company_id], unique: true, if_not_exists: true
    add_index :contact_companies, [:company_id, :contact_id], if_not_exists: true
    add_index :contact_companies, :deleted_at, if_not_exists: true
  end
end
