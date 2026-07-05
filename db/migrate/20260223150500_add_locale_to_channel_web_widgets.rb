class AddLocaleToChannelWebWidgets < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_web_widgets, :locale, :string, if_not_exists: true
  end
end
