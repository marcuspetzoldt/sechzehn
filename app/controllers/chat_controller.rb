class ChatController < ApplicationController

  def save
    @chats = Chat.send_message(current_user.id, params[:chat][:chat])
    redirect_to chat_show_path
  end

  def messages
    @chats = nil
    max_id = Chat.maximum(:id)
    if session['most_recent_chat'].nil? or session['most_recent_chat'] != max_id
      session['most_recent_chat'] = max_id
      @chats = Chat.get_newest_messages
    end
  end

  def show
    @chats = Chat.get_newest_messages
  end
end
