class ChatsController < ApplicationController

  def save
    Chat.create(user_id: current_user.id, chat: params[:chat][:chat])
    Pusher['sechzehn'].trigger('chats', {
      user: User.find(current_user.id).name,
      message: params[:chat][:chat]
    })
    render nothing: true
  end

end