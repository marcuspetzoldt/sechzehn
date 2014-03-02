class Score < ActiveRecord::Base
  belongs_to :user

  def self.score_types
    { all_time: 0, daily: 1 }
  end
end
