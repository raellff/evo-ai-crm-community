# frozen_string_literal: true

class AddAccountIdToContacts < ActiveRecord::Migration[7.1]
  def change
    add_reference :contacts, :account, type: :uuid, foreign_key: true, index: true
    
    # Remover índice único antigo de email
    remove_index :contacts, :email if index_exists?(:contacts, :email)
    
    # Criar índice composto account_id e email
    add_index :contacts, [:account_id, :email], unique: true, where: "email IS NOT NULL AND email <> ''"
    
    # Remover índice único antigo de phone_number
    remove_index :contacts, :phone_number if index_exists?(:contacts, :phone_number)
    
    # Criar índice composto account_id e phone_number
    add_index :contacts, [:account_id, :phone_number], where: "phone_number IS NOT NULL AND phone_number <> ''"
    
    # Remover índice único antigo de identifier
    remove_index :contacts, :identifier if index_exists?(:contacts, :identifier)
    
    # Criar índice composto account_id e identifier
    add_index :contacts, [:account_id, :identifier], unique: true, where: "identifier IS NOT NULL AND identifier <> ''"
    
    # Remover índice único antigo de tax_id
    remove_index :contacts, :tax_id if index_exists?(:contacts, :tax_id)
    
    # Criar índice composto account_id e tax_id
    add_index :contacts, [:account_id, :tax_id], unique: true, where: "tax_id IS NOT NULL"
    
    change_column_null :contacts, :account_id, true
  end
end
