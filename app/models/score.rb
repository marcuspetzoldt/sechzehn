class Score < ActiveRecord::Base
  belongs_to :user

  def self.score_types
    { all_time: 0, weekly: 1, dayliy: 2 }
  end
end
