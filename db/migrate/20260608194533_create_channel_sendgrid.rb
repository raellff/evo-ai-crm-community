class CreateChannelSendgrid < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_sendgrid, id: :uuid, default: -> { 'gen_random_uuid()' }, if_not_exists: true do |t|
      t.text :api_key_encrypted, null: false
      t.string :from_email, null: false
      t.string :from_name
      t.string :reply_to
      t.string :sender_domain

      t.timestamps
    end

    add_index :channel_sendgrid, :from_email, if_not_exists: true
  end
end
