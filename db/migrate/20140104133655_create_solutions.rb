class CreateSolutions < ActiveRecord::Migration
  def change
    create_table :solutions do |t|
      t.string :word
    end
    add_index :solutions, :word, using: 'btree', unique: true
  end
end
