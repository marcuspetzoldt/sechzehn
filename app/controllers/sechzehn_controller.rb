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
      # update elo without updating updated_at which is used in a nightly job to determine if player is still actively playing
      # update game_id which is used to recognize spectators
      current_user.update_columns(elo: current_user.new_elo, game_id: game_id) if signed_in?
      response.headers['X-Refreshed'] = '0'
    else
      # continue a game
      response.headers['X-Refreshed'] = '2'
    end
    render inline: init_field
  end

  def show
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
      if params[:what]
        @play = false
        # Highscores of the month
        @highscore = {which: 1}
        count, sql = highscore_sql(' ORDER BY ppoints DESC, cpoints DESC, cwords DESC', true, 1, 0)
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
      @user = User.new
      @play = false
      @highscore = {which: 1}
      count, sql = highscore_sql(' ORDER BY ppoints DESC, cpoints DESC, cwords DESC', true, 1, 0)
      @scores = ActiveRecord::Base.connection.execute(sql)
    end
    @letters = init_field
  end

  def solution

    return if current_user.nil?

    @tpoints = 0
    @twords = 0
    @cpoints = 0
    @cwords = 0
    @scores = []
    @words = []

    game_id = Game.maximum(:id)
    time_left = 210 - (Time.now - Game.find_by(id: game_id).updated_at)
    # during a game, show scores of last game
    game_id -= 1
    @words = ActiveRecord::Base.connection.execute(
        "SELECT s.word AS word, array_agg(g.user_id) AS format" +
        '  FROM solutions s' +
        '  LEFT JOIN guesses g' +
        '    ON s.word = g.word' +
        '   AND s.game_id = g.game_id' +
        " WHERE s.game_id = #{game_id}" +
        ' GROUP BY s.word' +
        ' ORDER BY length(s.word) DESC, s.word ASC'
    ).map do |s|
      @tpoints = @tpoints + letter_score[s['word'].length]
      s['format'].gsub!(/[\{\,]/,' usr')
      s['format'].sub!(/}/, ' ')
      if s['format'] =~ / usr#{current_user.id} /
        @cwords = @cwords + 1
        @cpoints = @cpoints + letter_score[s['word'].length]
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

    # Player score
    @twords = @words.length

    # All player's score
    @scores = ActiveRecord::Base.connection.execute(
      'SELECT a.id, a.guest, a.name, a.elo, count(b.points), sum(b.points)' +
      '  FROM users a' +
      ' LEFT JOIN guesses b' +
      '    ON a.id = b.user_id' +
      '   AND b.game_id = ' + game_id.to_s +
      '   AND b.points > 0' +
      ' WHERE a.game_id >= ' + game_id.to_s +
      ' GROUP BY a.id ' +
      ' ORDER BY SUM(b.points) DESC NULLS LAST, count(b.points) DESC NULLS LAST, a.name ASC')

    if time_left.to_i > 180
      compute_highscore if @cpoints > 0
    else
      @words = nil
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
        end
        if Guess.find_by(user_id: current_user.id, game_id: game_id, word: word).nil?
          Guess.create(user_id: current_user.id, game_id: game_id, word: word, points: points)
          session[:word_count] += 1
          session[:points] += points
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
        time_left = 210 - (Time.now - Game.find_by(id: game_id).updated_at)
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
      render text: 'maintenance'
      return
    end
    render text: time_left.to_s
  end

  def help
    @help = true
    @subtitle = 'Hilfe'
    @description = 'Hier findest Du die die Regeln von Sechzehn, sowie eine Erklärung der Bedienung von Sechzehn, und das Impressum.'
  end

  def highscore_elo
    highscore(' ORDER BY u.elo DESC, cpoints DESC, cwords DESC', 'elo')
  end

  def highscore_points
    highscore(' ORDER BY cpoints DESC, u.elo DESC, cwords DESC', 'cpoints')
  end

  def highscore_points_percent
    highscore(' ORDER BY ppoints DESC, u.elo DESC, cwords DESC', 'ppoints')
  end

  def highscore_words
    highscore(' ORDER BY cwords DESC, cpoints DESC, u.elo DESC', 'cwords')
  end

  def highscore_words_percent
    highscore(' ORDER BY pwords DESC, ppoints DESC, u.elo DESC', 'pwords')
  end

  def highscore(order_by, highscore_type)
    @help = true
    @canonical = 'http://spiele.sechzehn.org/highscore/elo'
    @description = 'Sechzehn ist ein Wortspiel wie Boggle. Finde innerhalb von 3 Minuten mehr deutsche Wörter in einem Quadrat mit 16 zufälligen Buchstaben als deine Mitspieler.'
    @description = 'Als registrierter Spieler von Sechzehn, kannst Du in diesen täglichen, wöchentlichen und monatlichen, sowie in einer ewigen Rangliste um Plätze kämpfen.'

    @highscore = {}
    @highscore[:which] = params[:which].to_i
    @highscore[:offset] = params[:offset] ? params[:offset].to_i : 0
    @highscore[:count], sql = highscore_sql(order_by, false, @highscore[:which], @highscore[:offset])
    case @highscore[:which]
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
      @highscore[:which] = 0
      @subtitle = 'ewige Rangliste'

    end
    @highscore[:type] = highscore_type
    @highscore[:rows] = ActiveRecord::Base.connection.execute(sql)
    render 'highscore'
  end

  def highscore_sql(order_by, homepage, which, offset)
    case which
    when 3
      # daily
      select = 'SELECT u.id, u.name, u.elo, s.count as count, s.cwords as cwords, s.pwords as pwords, s.cpoints as cpoints, s.ppoints as ppoints'
      where = '  FROM users u' +
          '  JOIN scores s' +
          '    ON u.id = s.user_id' +
          '   AND s.score_type = ' + Score.score_types[:daily].to_s +
          '   AND s.created_at >= \'' + Date.today.to_s + '\'' +
          ' WHERE u.elo > 0'
      group = ''

    when 2
      # weekly
      select = 'SELECT u.id, u.name, u.elo, sum(s.count) as count, sum(s.cwords*s.count)/sum(s.count) as cwords, sum(s.pwords*s.count)/sum(s.count) as pwords, sum(s.cpoints*s.count)/sum(s.count) as cpoints, sum(s.ppoints*s.count)/sum(s.count) as ppoints'
      where = '  FROM users u' +
          '  JOIN scores s' +
          '    ON u.id = s.user_id' +
          '   AND s.score_type = ' + Score.score_types[:daily].to_s +
          '   AND s.created_at >= \'' + Date.today.beginning_of_week.to_s + '\'' +
          ' WHERE u.elo > 0'
      group = ' GROUP BY u.id, u.name, u.elo, s.user_id'

    when 1
      # monthly
      select = 'SELECT u.id, u.name, u.elo, sum(s.count) as count, sum(s.cwords*s.count)/sum(s.count) as cwords, sum(s.pwords*s.count)/sum(s.count) as pwords, sum(s.cpoints*s.count)/sum(s.count) as cpoints, sum(s.ppoints*s.count)/sum(s.count) as ppoints'
      where = '  FROM users u' +
          '  JOIN scores s' +
          '    ON u.id = s.user_id' +
          '   AND s.score_type = ' + Score.score_types[:daily].to_s +
          '   AND s.created_at >= \'' + Date.today.beginning_of_month.to_s + '\'' +
          ' WHERE u.elo > 0'
      group = ' GROUP BY u.id, u.name, u.elo, s.user_id'

    else
      # all time
      select = 'SELECT u.id, u.name, u.elo, s.count as count, s.cwords as cwords, s.pwords as pwords, s.cpoints as cpoints, s.ppoints as ppoints'
      where = '  FROM users u' +
          '  JOIN scores s' +
          '    ON u.id = s.user_id' +
          '   AND s.score_type = ' + Score.score_types[:all_time].to_s +
          ' WHERE u.elo > 0'
      group = ''

    end
    result = ActiveRecord::Base.connection.execute('SELECT COUNT(DISTINCT u.id) AS count ' + where)
    if result.count == 1
      count = result[0]['count'].to_i
    else
      count = 0
    end
    if homepage
      sql = select + where + group + order_by + ' LIMIT 10'
    else
      sql = select + where + group + order_by + ' LIMIT 100 OFFSET ' + offset.to_s
    end
    [count, sql]
  end

  def maintenance
    render 'maintenance'
  end

  private

    def letter_score
      [0, 0, 0, 1, 1, 2, 3, 5, 11, 11, 11, 11, 11, 11, 11, 11, 11]
    end

    def init_field
      if session[:game_id]
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

    def compute_highscore

      # cleanup
      Score.where('user_id=? and score_type=? and created_at<?', current_user.id, Score.score_types[:daily], Date.today-1.month).destroy_all

      # Player played a game
      current_user.touch

      begin
        score = Score.find_by!(user_id: current_user.id, score_type: Score.score_types[:all_time] )
      rescue ActiveRecord::RecordNotFound
        score = Score.new(user_id: current_user.id, game_id: 0, score_type: Score.score_types[:all_time], count: 0, cwords: 0, pwords: 0, cpoints: 0, ppoints: 0)
      end

      begin
        score_daily = Score.find_by!(user_id: current_user.id, score_type: Score.score_types[:daily], created_at: Date.today )
      rescue ActiveRecord::RecordNotFound
        score_daily = Score.new(user_id: current_user.id, game_id: 0, score_type: Score.score_types[:daily], count: 0, cwords: 0, pwords: 0, cpoints: 0, ppoints: 0, created_at: Date.today)
      end

      if !session[:game_id].nil? and session[:game_id] > score.game_id
        score.cwords = (score.cwords * score.count + @cwords) / (score.count + 1)
        score.pwords = (score.pwords * score.count + (@cwords * 100 / @twords)) / (score.count + 1)
        score.cpoints = (score.cpoints * score.count + @cpoints) / (score.count + 1)
        score.ppoints = (score.ppoints * score.count + (@cpoints * 100 / @tpoints)) / (score.count + 1)
        score.count = score.count + 1
        score.game_id = session[:game_id]

        score_daily.cwords = (score_daily.cwords * score_daily.count + @cwords) / (score_daily.count + 1)
        score_daily.pwords = (score_daily.pwords * score_daily.count + (@cwords * 100 / @twords)) / (score_daily.count + 1)
        score_daily.cpoints = (score_daily.cpoints * score_daily.count + @cpoints) / (score_daily.count + 1)
        score_daily.ppoints = (score_daily.ppoints * score_daily.count + (@cpoints * 100 / @tpoints)) / (score_daily.count + 1)
        score_daily.count = score_daily.count + 1
        score_daily.game_id = session[:game_id]

        delta_elo = 0
        @scores.each do |s|
          if (s['id'].to_i != score.user_id) and (s['guest'].nil?) and (s['sum'].to_i > 0)
            r = s['elo'].to_f - current_user.elo.to_f
            r = ((r > 0) ? 400.0 : -400.0) if r.abs > 400.0
            ea = 1.0 / (1.0 + 10.0 ** (r / 400.0))
            delta_elo = delta_elo + k_factor(score) * (sa(s['sum'].to_i) - ea)
          end
        end
        new_elo = current_user.elo + delta_elo
        current_user.update_attribute(:new_elo, new_elo)
        if registered_user?
          score.save
          score_daily.save
        end
      end
    end

    def sa(opponent_points)
      # win: 1, loss: 0, tie: 0.5
      case opponent_points <=> @cpoints
      when -1
        1
      when 1
        0
      else
        0.5
      end
    end

    def k_factor(me)
      # casual player: 30, frequent player: 15, frequent very good player: 10
      if current_user.elo > 2400
        10
      else
        if me.count > 30
          15
        else
          30
        end
      end
    end

end
