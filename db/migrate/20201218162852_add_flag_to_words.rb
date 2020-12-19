class AddFlagToWords < ActiveRecord::Migration[6.0]
  def change
    add_column :words, :flag, :integer, default: 0
    add_column :words, :comment, :string
  end
end
