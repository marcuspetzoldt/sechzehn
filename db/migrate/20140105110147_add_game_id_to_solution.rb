class AddGameIdToSolution < ActiveRecord::Migration
  def change
    add_column :solutions, :game_id, :integer
    remove_index :solutions, :word
    add_index :solutions, [:game_id, :word], using: 'btree', unique: true
  end
end
