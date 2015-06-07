# TODO: Stop nightly recalculation of elo
desc "Called by Heroku scheduler, decreases ELO of inactive players by one per day"
task :recalculate_elo => :environment do
  puts "Recalculating ELO ..."
  User.where("guest IS NULL AND elo > 0 AND updated_at IS NOT NULL").each do |u|
    delta_hours = ((Time.now - u.updated_at) / 3600.0).to_i
    if delta_hours > 23
      delta_days = delta_hours / 24
      elo = u.new_elo - delta_days * 4
      elo = 0 if elo < 0
      u.update_columns(elo: elo, new_elo: elo)
      u.touch
    end
  end
  puts "done."
end
