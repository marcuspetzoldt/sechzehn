#User.all.each do |u|
#  u.elo = 1600
#  u.new_elo = 1600
#  u.save
#end
ActiveRecord::Base.connection.execute('UPDATE scores set perfw=0, perfp=0, perfc=0')
