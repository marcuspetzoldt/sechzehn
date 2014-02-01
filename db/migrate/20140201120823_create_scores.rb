class CreateScores < ActiveRecord::Migration
  def change
    create_table :scores do |t|
      t.integer :user_id
      t.integer :type
      t.integer :count
      t.float :cwords
      t.float :pwords
      t.float :cpoints
      t.float :ppoints
      t.integer :elo
    end
  end
end
