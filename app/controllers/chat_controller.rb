class ChatController < ApplicationController

  def save
    c = Chat.new(user_id: current_user.id, chat: params[:chat][:chat])
    c.save
    @chats = Chat.where("created_at > '#{Time.now.utc - 30.minutes}'").order(:created_at)
    redirect_to chat_show_path
  end

  def messages
    @chats = Chat.where("created_at > '#{Time.now.utc - 30.minutes}'").order(:created_at)
  end

  def show
    @chats = Chat.where("created_at > '#{Time.now.utc - 30.minutes}'").order(:created_at)
  end
end
