desc "Called by Heroku scheduler, removes obsolete solutions from db."
task :remove_old_solutions => :environment do
  puts "Removing old solution ..."
    max_game_id = Game.maximum(:id) - 1
    Solution.delete_all("game_id < #{max_game_id}")
  puts "Removing old messages ..."
    Chat.delete_all("created_at < '#{Time.now.utc - 30.minutes}'")
  puts "Removing old guesses ..."
    Guess.delete_all("game_id < #{max_game_id} AND (points <> 0 OR game_id IS NULL)")
  puts "Removing guests ..."
    User.delete_all("guest = 1 AND created_at < '#{Time.now.utc - 1.weeks}'")
  puts "done."
end