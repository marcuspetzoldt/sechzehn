class AddIndexToWord < ActiveRecord::Migration
  def change
    add_index :words, :word, using: 'btree', unique: true
  end
end
