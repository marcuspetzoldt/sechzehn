class Guess < ActiveRecord::Base

  belongs_to :game
  belongs_to :user

  validates :word, presence: true

end
