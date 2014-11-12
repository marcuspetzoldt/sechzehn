desc "Called by Heroku scheduler, decreases ELO of inactive players by one per day"
task :recalculate_elo => :environment do
  puts "Recalculating ELO ..."
  User.where("guest IS NULL AND elo > 0 AND updated_at IS NOT NULL").each do |u|
    delta_days = (Date.today - u.updated_at.to_datetime).to_i - 1
    if delta_days > 1
      elo = u.new_elo - delta_days
      elo = 0 if elo < 0
      u.update_columns(elo: elo, new_elo: elo)
      u.touch
    end
  end
  puts "done."
end
