class CreateGuesses < ActiveRecord::Migration
  def change
    create_table :guesses do |t|
      t.integer :user_id
      t.integer :game_id
      t.string :word
    end
    add_index :guesses, [:game_id, :user_id, :word], using: 'btree', unique: true
  end
end
