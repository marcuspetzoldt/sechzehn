class AddColumnsPerformanceToScores < ActiveRecord::Migration
  def change
    add_column :scores, :perfw, :float
    add_column :scores, :perfp, :float
    add_column :scores, :perfc, :integer
  end
end
