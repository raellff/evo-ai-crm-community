class AddCompanyFieldsToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :tax_id, :string, limit: 14, if_not_exists: true
    add_column :contacts, :website, :string, if_not_exists: true
    add_column :contacts, :industry, :string, if_not_exists: true

    # Índice para tax_id (CNPJ/CPF)
    add_index :contacts, [:tax_id], unique: true, where: "tax_id IS NOT NULL", if_not_exists: true
  end
end
