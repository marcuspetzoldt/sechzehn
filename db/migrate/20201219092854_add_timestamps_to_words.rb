class AddTimestampsToWords < ActiveRecord::Migration[6.0]
  def change
    add_timestamps :words, null: false, default: DateTime.new(1970,1,1)
  end
end
