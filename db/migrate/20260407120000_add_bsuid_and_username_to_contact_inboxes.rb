class AddBsuidAndUsernameToContactInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :contact_inboxes, :bsuid, :text, if_not_exists: true
    add_column :contact_inboxes, :whatsapp_username, :text, if_not_exists: true
    add_index :contact_inboxes, %i[inbox_id bsuid], unique: true, where: 'bsuid IS NOT NULL', name: 'index_contact_inboxes_on_inbox_id_and_bsuid', if_not_exists: true
  end
end
