class CreateBans < ActiveRecord::Migration
  def change
    create_table :bans do |t|
      t.string :ip

      t.timestamps
    end
  end
end
