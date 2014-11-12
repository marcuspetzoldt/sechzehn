desc "Called by Heroku scheduler, removes obsolete solutions from db."
task :remove_old_solutions => :environment do
  puts "Removing old solution ..."
    max_game_id = Game.maximum(:id) - 1
    Solution.delete_all("game_id < #{max_game_id}")
  puts "done."
end