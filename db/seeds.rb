User.all.each do |u|
  u.elo = 1600
  u.new_elo = 1600
  u.save
end