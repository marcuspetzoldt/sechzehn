class Chat < ActiveRecord::Base

  belongs_to :user

  def self.send_message(user_id, message)
    Chat.create(user_id: user_id, chat: message)
    self.get_newest_messages
  end

  def self.get_newest_messages
    Chat.where("created_at > '#{Time.now.utc - 30.minutes}'").order(:created_at)
  end

end
