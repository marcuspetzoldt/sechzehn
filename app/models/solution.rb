class Solution < ActiveRecord::Base

  belongs_to :game

  validates :word, presence: true

end
