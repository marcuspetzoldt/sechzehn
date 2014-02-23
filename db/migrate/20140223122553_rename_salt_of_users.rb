class RenameSaltOfUsers < ActiveRecord::Migration
  def change
    remove_index :users, 'name_and_salt'
    rename_column :users, 'salt', 'guest'
  end
end
