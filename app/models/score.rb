class Score < ActiveRecord::Base
  def self.types
    { all_time: 0, weekly: 1, dayliy: 2 }
  end
end
