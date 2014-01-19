class Lock < ActiveRecord::Base

  before_create :set_lock

  private

    def set_lock
      self.lock = 1
    end

end
