class ChatsController < ApplicationController

  def save
    unless params[:chat][:chat].blank?
      ip = request.remote_ip
      unless Ban.find_by(ip: ip)
        Chat.create(user_id: current_user.id, chat: params[:chat][:chat], ip: ip)
        # Secret from the firebase.com secrets tab of sizzling-torch-1432 app
        firebase = Firebase::Client.new('https://luminous-inferno-1701.firebaseio.com/', '5mGdZZ5NoMqtEam3KwY8ZfB5QXOeG0RfvgAf3NK2')
        response = firebase.set('chat', { usr: current_user.name, msg: params[:chat][:chat] })
      end
    end
    render nothing: true
  end

end