class AddEmailSignatureToChannelEmail < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_email, :email_signature, :text, if_not_exists: true
  end
end
