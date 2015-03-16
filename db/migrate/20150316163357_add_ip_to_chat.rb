class AddIpToChat < ActiveRecord::Migration
  def change
    add_column :chats, :ip, :string
  end
end
