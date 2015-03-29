class ChatsController < ApplicationController

  def save
    unless params[:chat][:chat].blank?
      ip = request.remote_ip
      unless Ban.find_by(ip: ip)
        Chat.create(user_id: current_user.id, chat: params[:chat][:chat], ip: ip)
        Pusher['sechzehn'].trigger('chats', {
          user: User.find(current_user.id).name,
          message: params[:chat][:chat]
        })
      end
    end
    render nothing: true
  end

end