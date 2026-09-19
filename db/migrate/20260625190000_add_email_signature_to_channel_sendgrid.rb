class AddEmailSignatureToChannelSendgrid < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_sendgrid, :email_signature, :text, if_not_exists: true
  end
end
