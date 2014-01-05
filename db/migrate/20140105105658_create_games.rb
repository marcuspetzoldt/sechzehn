class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :letters

      t.timestamps
    end
  end
end
