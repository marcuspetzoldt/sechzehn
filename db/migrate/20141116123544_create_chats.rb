class CreateChats < ActiveRecord::Migration
  def change
    create_table :chats do |t|
      t.integer :user_id
      t.text :chat

      t.timestamps
    end
  end
end
