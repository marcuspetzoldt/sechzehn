class AddEmailDigestToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :email_digest, :string
  end
end
