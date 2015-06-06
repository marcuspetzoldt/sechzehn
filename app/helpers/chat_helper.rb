module ChatHelper
  def firebase_say(name, message, system)
    firebase = Firebase::Client.new('https://luminous-inferno-1701.firebaseio.com/', '5mGdZZ5NoMqtEam3KwY8ZfB5QXOeG0RfvgAf3NK2')
    firebase.push('chat', { usr: name, msg: message, sys: system })
  end
end
