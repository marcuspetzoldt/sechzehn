class ChatsController < ApplicationController

  def save
    unless params[:chat][:chat].blank?
      ip = request.remote_ip
      unless Ban.find_by(ip: ip)
        Chat.create(user_id: current_user.id, chat: params[:chat][:chat], ip: ip)
        # Secret from the firebase.com secrets tab of sizzling-torch-1432 app
        firebase_say(current_user.name, params[:chat][:chat], 0)
      end
    end
    render nothing: true
  end

end