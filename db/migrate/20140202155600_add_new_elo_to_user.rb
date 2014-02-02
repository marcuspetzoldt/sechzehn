class AddNewEloToUser < ActiveRecord::Migration
  def change
    add_column :users, :new_elo, :integer, default: 1600
  end
end
