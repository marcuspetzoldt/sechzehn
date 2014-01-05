class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.integer :salt
      t.string :password_digest
    end
    add_index :users, [:name, :salt], using: 'btree', unique: true
  end
end
