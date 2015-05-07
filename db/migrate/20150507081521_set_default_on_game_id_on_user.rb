class SetDefaultOnGameIdOnUser < ActiveRecord::Migration
  def change
    change_column_default :users, :game_id, 0
  end
end
