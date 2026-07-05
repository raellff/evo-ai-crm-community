class AddTypeToContacts < ActiveRecord::Migration[7.1]
  def up
    # Criar tipo ENUM no PostgreSQL
    execute <<-SQL
      DO $$ BEGIN
        CREATE TYPE contact_type_enum AS ENUM ('person', 'company');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    SQL

    # Adicionar coluna com ENUM
    unless column_exists?(:contacts, :type)
      add_column :contacts, :type, :contact_type_enum, default: 'person', null: false, if_not_exists: true
    end

    add_index :contacts, :type, if_not_exists: true unless index_exists?(:contacts, :type)

    # Composite index from OptimizeContactsPerformance (20241020000100). That migration
    # has an earlier timestamp than this one, so on fresh installs it ran before `type`
    # existed and skipped creating the composite index. Backfill it here.
    execute <<-SQL
      CREATE INDEX IF NOT EXISTS idx_contacts_name_type_resolved
      ON contacts (name, type, id)
      WHERE (email <> '' OR phone_number <> '' OR identifier <> '');
    SQL

    # Atualizar contatos existentes para 'person'
    Contact.where(type: nil).update_all(type: 'person') if column_exists?(:contacts, :type)
  end

  def down
    remove_index :contacts, :type
    remove_column :contacts, :type
    
    # Remover tipo ENUM do PostgreSQL
    execute <<-SQL
      DROP TYPE IF EXISTS contact_type_enum;
    SQL
  end
end
