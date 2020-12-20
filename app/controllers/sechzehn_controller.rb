class SechzehnController < ApplicationController

  before_action :maintenance?, except: [:sync, :solution, :guess, :maintenance]

  def new
    game_id = Game.maximum(:id)
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
    if game_id != session[:game_id].to_i
      # start a new game
      if session[:cap] && session[:cap] > 400
        Rails.logger.error("Word counter reached #{session[:cap]}")
      end
      start_game(game_id)
      # update game_id which is used to recognize spectators
      if current_user.game_id < (game_id-1)
        firebase_say(current_user.name, 'spielt jetzt mit', 1) if Rails.env.production?
      end

      current_user.update_columns(game_id: game_id) if signed_in?
      response.headers['X-Refreshed'] = '0'
    else
      # continue a game
      response.headers['X-Refreshed'] = '2'
    end
    render inline: init_field
  end

  def show
    @word = Word.new
    @canonical = 'http://spiele.sechzehn.org/'
    @description = 'Sechzehn ist ein Wortspiel wie Boggle. Finde innerhalb von 3 Minuten die meisten deutschen Wörter in einem Quadrat mit 16 zufälligen Buchstaben.'
    @subtitle = 'ein Wortspiel auf deutsch'
    @play = true
    @cwords = 0
    @cpoints = 0
    @guesses = []
    @scores = []
    if signed_in?
      @user = current_user
      if params[:form]
        @play = false
        # Highscores of the month
        @highscore = {which: 1}
        count, sql = highscore_sql(1, true, 1, 0, 0)
        @scores = ActiveRecord::Base.connection.execute(sql)
      else
        # Active player
        @cwords, @cpoints = get_score
        session[:word_count] = @cwords
        session[:points] = @cpoints
        @guesses = Guess.where(game_id: session[:game_id], user_id: @user.id).order(id: :desc).map do |guess|
          [guess.word, guess.points]
        end
      end
    else
      @user = params[:name] ? User.new(name: params[:name]) : User.new
      @play = false
      @highscore = {which: 1}
      count, sql = highscore_sql(1, true, 1, 0, 1)
      @scores = ActiveRecord::Base.connection.execute(sql)
    end
    @letters = init_field
  end

  def leaderboard

    @leaderboard = {}
    game_id = Game.maximum(:id) - 1
    total = get_totals(game_id)
    @leaderboard[:total_words] = total[:words]
    @leaderboard[:total_points] = total[:points]
    # All player's score
    @leaderboard[:scores] = ActiveRecord::Base.connection.execute(
      'SELECT a.id, a.guest, a.name, count(b.points), sum(b.points)' +
      '  FROM users a' +
      ' LEFT JOIN guesses b' +
      '    ON a.id = b.user_id' +
      '   AND b.game_id = ' + game_id.to_s +
      '   AND b.points > 0' +
      ' WHERE a.game_id >= ' + game_id.to_s +
      ' GROUP BY a.id ' +
      ' ORDER BY SUM(b.points) DESC NULLS LAST, count(b.points) ASC NULLS LAST, a.name ASC')

  end

  def solution

    if current_user.nil?
      render nothing: true
      return
    end

    @solution = {}
    @solution[:cwords] = 0
    @solution[:cpoints] = 0
    @solution[:words] = []

    game_id = Game.maximum(:id)
    time_left = 210 - (Time.now - Game.find(game_id).updated_at)
    # during a game, show scores of last game
    game_id -= 1
    @solution[:words] = ActiveRecord::Base.connection.execute(
        "SELECT s.word AS word, array_agg(g.user_id) AS format" +
        '  FROM solutions s' +
        '  LEFT JOIN guesses g' +
        '    ON s.word = g.word' +
        '   AND s.game_id = g.game_id' +
        " WHERE s.game_id = #{game_id}" +
        ' GROUP BY s.word' +
        ' ORDER BY length(s.word) DESC, s.word ASC'
    ).map do |s|
      s['format'].gsub!(/[\{\,]/,' usr')
      s['format'].sub!(/}/, ' ')
      if s['format'] =~ / usr#{current_user.id} /
        @solution[:cwords] += 1
        @solution[:cpoints] += letter_score[s['word'].length]
        if s['format'] =~ /. ./
          # Player and others found the word
          format = 'self '
        else
          # Only player found the word
          format = 'onlyself '
        end
      else
        if s['format'] =~ /NULL/
          # Noone found the word
          format = 'noone '
          s['format'] = ''
        else
          # Someone found the word
          format = 'someone '
        end
      end
      format = ('guess ' + format + s['format']).chop
      [s['word'], s['word'].length, letter_score[s['word'].length], format]
    end

    @solution[:total] = get_totals(game_id)
    if (@solution[:cpoints] > 0) and (time_left.to_i > 180)
      compute_highscore(@solution[:cwords], @solution[:cpoints], @solution[:total][:words], @solution[:total][:points])
    end

  end

  def guess

    success = false
    unless current_user.nil?
      success = true
      game_id = Game.maximum(:id)
      word = params['words'].downcase
      points = 0
      if (session[:cap] += 1) < 400
        unless Solution.find_by(game_id: game_id, word: word).nil?
          points = letter_score[word.length]
          if Guess.find_by(user_id: current_user.id, game_id: game_id, word: word).nil?
            Guess.create(user_id: current_user.id, game_id: game_id, word: word, points: points)
            session[:word_count] += 1
            session[:points] += points
          end
        end
      end
    end
    time_left = 210 - (Time.now - session[:start_time])
    render json: {success: success, word: word, points: points, cwords: session[:word_count], cpoints: session[:points], time: time_left.to_i}
  end

  def sync
    if Lock.find_by(lock: 2).nil?
      if Lock.find_by(lock: 1).nil?
        game_id = Game.maximum(:id)
        if game_id
          time_left = 210 - (Time.now - Game.find_by(id: game_id).updated_at)
        else
          time_left = -1
        end
        if time_left <= 0
          begin
            l = Lock.create
            Rails.logger.info('GAMECREATION: Start')
            g = Game.create
            time_left = 210 - (Time.now - g.updated_at)
            Rails.logger.info('GAMECREATION: End')
            l.destroy
          rescue ActiveRecord::RecordNotUnique
            # Another player already computes the next game.
            # Sync again
            time_left = -1
          ensure
            l.destroy unless l.nil?
          end
        end
      else
        # Another player computes the next game.
        # Sync again.
        time_left = -1
      end
    else
      render inline: 'maintenance'
      return
    end
    render inline: time_left.to_s
  end

  def help
    @reduced_navbar = true
    @subtitle = 'Hilfe'
    @description = 'Hier findest Du die die Regeln von Sechzehn, sowie eine Erklärung der Bedienung von Sechzehn, und das Impressum.'
  end

  def highscore_daily
    highscore(3)
  end

  def highscore_weekly
    highscore(2)
  end

  def highscore_monthly
    highscore(1)
  end

  def highscore_eternal
    highscore(0)
  end

  def highscore(interval)
    @reduced_navbar = true
    @canonical = 'http://spiele.sechzehn.org/highscore/points/percent'
    @description = 'Sechzehn ist ein Wortspiel wie Boggle. Finde innerhalb von 3 Minuten mehr deutsche Wörter in einem Quadrat mit 16 zufälligen Buchstaben als deine Mitspieler.'
    @description = 'Als registrierter Spieler von Sechzehn, kannst Du in diesen täglichen, wöchentlichen und monatlichen, sowie in einer ewigen Rangliste um Plätze kämpfen.'

    @highscore = {}
    @highscore[:interval] = interval
    @highscore[:offset] = params[:offset] ? params[:offset].to_i : 0
    case @highscore[:interval]
    when 3
      # daily
      @subtitle = 'Rangliste für ' + %w(Sonntag Montag Dienstag Mittwoch Donnerstag Freitag Samstag)[Date.today.wday]

    when 2
      # weekly
      @subtitle = 'Rangliste der ' + Date.today.cweek.to_s + '. KW'

    when 1
      # monthly
      @subtitle = 'Rangliste für ' + %w(Januar Februar März April Mai Juni Juli August September Oktober November Dezember)[Date.today.month-1]

    else
      # all time
      @highscore[:interval] = 0
      @subtitle = 'ewige Rangliste'
    end
    # Show points performance per default
    @highscore[:category] = 2
    @highscore[:category] = params[:category].to_i if params[:category]
    @highscore[:cutoff] = 0
    @highscore[:cutoff] = params[:cutoff].to_i if params[:cutoff]
    @highscore[:count], sql = highscore_sql(@highscore[:category], false, @highscore[:interval], @highscore[:offset], @highscore[:cutoff])
    rank = @highscore[:offset]
    old_value = 0
    @highscore[:rows] = ActiveRecord::Base.connection.execute(sql).map do |score|
      rank = rank + 1
      if old_value != score['value']
        old_value = score['value']
        rank_string = rank.to_s
      else
        rank_string = ''
      end
      case @highscore[:category].to_i
      when 1, 4
        value = "#{score['value'].to_f.round(2)} %"
        count = score['count'].to_s
      when 2, 5
        value = "#{score['value'].to_f.round}"
        count = score['count'].to_s
      else
        value = score['value'].to_f.round(2).to_s
        count = score['count'].to_s
      end
      {id: score['id'].to_i, rank: rank_string, name: score['name'], count: count, value: value}
    end
    render 'highscore'
  end

  def highscore_sql(category, homepage, interval, offset, cutoff_index)

    case cutoff_index
    when 1
      cutoff = 10
    when 2
      cutoff = 50
    when 3
      cutoff = 100
    else
      cutoff = 0
    end

    case category.to_i
    when 0
      category_s = 'cpoints'

    when 1
      category_s = 'ppoints'

    when 2
      category_s = 'perfp'

    when 3
      category_s = 'cwords'

    when 4
      category_s = 'pwords'

    when 5
      category_s = 'perfw'

    else
      category_s = 'perfp'

    end

    case interval
    when 3
      # daily
      select = "SELECT u.id, u.name, s.#{category_s} as value, s.count as count"
      join = '  FROM users u' +
          '  JOIN scores s' +
          '    ON u.id = s.user_id' +
          '   AND s.score_type = ' + Score.score_types[:daily].to_s +
          '   AND s.created_at >= \'' + Date.today.to_s + '\''
      where = " WHERE s.#{category_s} > 0" +
          " AND s.count > #{cutoff}"
      group = ''

    when 2
      # weekly
      select = "SELECT u.id, u.name, sum(s.#{category_s}*s.count)/sum(s.count) as value, sum(s.count) as count"
      join = '  FROM users u' +
          '  JOIN scores s' +
          '    ON u.id = s.user_id' +
          '   AND s.score_type = ' + Score.score_types[:daily].to_s +
          '   AND s.created_at >= \'' + Date.today.beginning_of_week.to_s + '\''
      where = ''
      group = ' GROUP BY u.id, u.name' +
        " HAVING sum(s.#{category_s}*s.count)/sum(s.count) > 0" +
        " AND sum(s.count) > #{cutoff}"

    when 1
      # monthly
      select = "SELECT u.id, u.name, sum(s.#{category_s}*s.count)/sum(s.count) as value, sum(s.count) as count"
      join = '  FROM users u' +
          '  JOIN scores s' +
          '    ON u.id = s.user_id' +
          '   AND s.score_type = ' + Score.score_types[:daily].to_s +
          '   AND s.created_at >= \'' + Date.today.beginning_of_month.to_s + '\''
      where = ''
      group = ' GROUP BY u.id, u.name' +
          " HAVING sum(s.#{category_s}*s.count)/sum(s.count) > 0" +
          " AND sum(s.count) > #{cutoff}"

    else
      # all time
      select = "SELECT u.id, u.name, #{category_s} as value, s.count as count"
      join = '  FROM users u' +
          '  JOIN scores s' +
          '    ON u.id = s.user_id' +
          '   AND s.score_type = ' + Score.score_types[:all_time].to_s
      where = " WHERE #{category_s} > 0" +
          " AND s.count > #{cutoff}"
      group = ''

    end
    result = ActiveRecord::Base.connection.execute('SELECT COUNT(DISTINCT u.id) AS count ' + join + where + ' LIMIT 20')
    if result.count == 1
      count = result[0]['count'].to_i
    else
      count = 0
    end
    if homepage
      sql = select + join + where + group + ' ORDER BY value DESC ' + ' LIMIT 10'
    else
      sql = select + join + where + group + ' ORDER BY value DESC ' + ' LIMIT 100 OFFSET ' + offset.to_s
    end
    [count, sql]
  end

  def maintenance
    @reduced_navbar = true
    Rails.logger.error("Maintenance and @help=#{@reduced_navbar}")
    render 'maintenance'
  end

  private

    def letter_score
      [0, 0, 0, 1, 1, 2, 3, 5, 11, 11, 11, 11, 11, 11, 11, 11, 11]
    end

    def init_field
      if session[:game_id] and !params['form']
        Game.find_by(id: session[:game_id]).letters.upcase
      else
        'RPOESECHZEHNDTEE'
      end
    end

    def get_score
      if signed_in?
        guesses = ActiveRecord::Base.connection.execute(
            'SELECT count(id) AS count, sum(points) AS sum' +
            '  FROM guesses' +
            " WHERE user_id = #{current_user.id.to_i}" +
            "   AND game_id = #{session[:game_id].to_i}" +
            '   AND points > 0'
        )
        [guesses[0]['count'].to_i, guesses[0]['sum'].to_i]
      else
        [0, 0]
      end
    end

    def compute_highscore(cwords, cpoints, twords, tpoints)

      average_words = 114.0 # 113.8432
      average_points = 235.0 # 235.3976

      # cleanup
      Score.where('user_id=? and score_type=? and created_at<?', current_user.id, Score.score_types[:daily], Date.today-1.month).destroy_all

      # Player played a game
      current_user.touch

      begin
        score = Score.find_by!(user_id: current_user.id, score_type: Score.score_types[:all_time] )
      rescue ActiveRecord::RecordNotFound
        score = Score.new(user_id: current_user.id, game_id: 0, score_type: Score.score_types[:all_time], count: 0, cwords: 0, pwords: 0, cpoints: 0, ppoints: 0, perfw: 0, perfp: 0, perfc: 0)
      end

      begin
        score_daily = Score.find_by!(user_id: current_user.id, score_type: Score.score_types[:daily], created_at: Date.today )
      rescue ActiveRecord::RecordNotFound
        score_daily = Score.new(user_id: current_user.id, game_id: 0, score_type: Score.score_types[:daily], count: 0, cwords: 0, pwords: 0, cpoints: 0, ppoints: 0, perfw: 0, perfp: 0, perfc: 0, created_at: Date.today)
      end

      if !session[:game_id].nil? and session[:game_id] > score.game_id

        performance_words = (cwords * 100.0 / twords)
        performance_points = (cpoints * 100.0 / tpoints)

        capped_words = twords > 2*average_words ? 2*average_words : twords
        capped_points = tpoints > 2*average_points ? 2*average_points : tpoints
        words_adjust = 1.0 - ((average_words - capped_words)/average_words) ** 7
        points_adjust = 1.0 - ((average_points - capped_points)/average_points) ** 7
        performance_words_adjusted = performance_words * words_adjust * 100
        performance_points_adjusted = performance_points * points_adjust * 100

        score.cwords = (score.cwords * score.count + cwords) / (score.count + 1)
        score.pwords = (score.pwords * score.count + performance_words) / (score.count + 1)
        score.cpoints = (score.cpoints * score.count + cpoints) / (score.count + 1)
        score.ppoints = (score.ppoints * score.count + performance_points) / (score.count + 1)
        score.perfw = (score.perfw * score.perfc + performance_words_adjusted) / (score.perfc + 1)
        score.perfp = (score.perfp * score.perfc + performance_points_adjusted) / (score.perfc + 1)
        score.count += 1
        score.perfc += 1
        score.game_id = session[:game_id]

        score_daily.cwords = (score_daily.cwords * score_daily.count + cwords) / (score_daily.count + 1)
        score_daily.pwords = (score_daily.pwords * score_daily.count + performance_words) / (score_daily.count + 1)
        score_daily.cpoints = (score_daily.cpoints * score_daily.count + cpoints) / (score_daily.count + 1)
        score_daily.ppoints = (score_daily.ppoints * score_daily.count + performance_points) / (score_daily.count + 1)
        score_daily.perfw = (score.perfw * score_daily.perfc + performance_words_adjusted) / (score_daily.perfc + 1)
        score_daily.perfp = (score.perfp * score_daily.perfc + performance_points_adjusted) / (score_daily.perfc + 1)
        score_daily.count += 1
        score_daily.perfc += 1
        score_daily.game_id = session[:game_id]

        if registered_user?
          score.save
          score_daily.save
        end
      end
    end

    def get_totals(game_id)
      total = ActiveRecord::Base.connection.execute(
          'SELECT count(word) as words, sum(points) as points' +
              '  FROM solutions' +
              ' WHERE game_id = ' + game_id.to_s
      )
      { words: total[0]['words'].to_i, points: total[0]['points'].to_i }
    end

end
