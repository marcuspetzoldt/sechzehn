class User < ActiveRecord::Base

  has_many :guesses
  has_secure_password

  validates :name, presence: true, length: { minimum: 3, maximum: 32 }
  validates :password, length: { minimum: 6 }
end
