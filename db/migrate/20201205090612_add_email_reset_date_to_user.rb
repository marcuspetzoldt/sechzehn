class AddEmailResetDateToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :email_reset_date, :datetime
  end
end
