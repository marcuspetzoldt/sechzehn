class AddColumnPointsToSolution < ActiveRecord::Migration
  def change
    add_column :solutions, :points, :integer
  end
end
