class CreateLocks < ActiveRecord::Migration
  def change
    create_table :locks do |t|
      t.integer :lock
    end
    add_index :locks, :lock, using: 'btree', unique: true
  end
end
