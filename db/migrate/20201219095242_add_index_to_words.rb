class AddIndexToWords < ActiveRecord::Migration[6.0]
  def change
    add_index :words, :updated_at, using: 'btree'
  end
end
