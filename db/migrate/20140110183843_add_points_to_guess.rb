class AddPointsToGuess < ActiveRecord::Migration
  def change
    add_column :guesses, :points, :integer
  end
end
