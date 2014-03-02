class AddTimestampToScore < ActiveRecord::Migration
  def change
    change_table :scores do |t|
      t.timestamps
    end
  end
end
