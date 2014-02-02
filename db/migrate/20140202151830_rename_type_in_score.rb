class RenameTypeInScore < ActiveRecord::Migration
  def change
    rename_column :scores, :type, :score_type
  end
end
