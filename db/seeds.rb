User.all.each do |u|
  u.elo = 1600
  u.save
end