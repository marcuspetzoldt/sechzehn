class AddEloToUser < ActiveRecord::Migration
  def change
    add_column :users, :elo, :integer, default: 1600
    remove_column :scores, :elo
  end
end
