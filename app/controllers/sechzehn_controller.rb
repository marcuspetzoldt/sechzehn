class SechzehnController < ApplicationController

  before_action :maintenance?, except: [:sync, :solution, :guess, :maintenance]

  def new
    game_id = Game.maximum(:id)
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    if game_id != session['game_id']
      # start a new game
      if signed_in?
        current_user.guesses.where('points <> 0').destroy_all if signed_in?
        current_user.update_attribute(:elo, current_user.new_elo)
      end
      session['game_id'] = Game.maximum(:id)
      response.headers['X-Refreshed'] = '0'
    else
      # continue a game
      response.headers['X-Refreshed'] = '2'
    end
    @field = init_field
    render partial: 'layouts/show_dice'
  end

  def show
    @canonical = 'http://spiele.sechzehn.org/'
    @play = true
    @cwords = 0
    @cpoints = 0
    @guesses = []
    if signed_in?
      @user = current_user
      if params[:what]
        @play = false
      else
        @cwords, @cpoints = get_score
        @guesses = Guess.where(game_id: session['game_id'], user_id: @user.id).reverse.map do |guess|
          [guess.word, guess.points]
        end
      end
    else
      @user = User.new
      @play = false
      session['game_id'] = nil
    end
    @field = init_field
  end

  def solution
    @tpoints = 0
    @twords = 0
    @cpoints = 0
    @cwords = 0
    @words = []
    @scores = []

    return if session['game_id'].nil?

    @words = Game.find_by(id: session['game_id']).solutions.map do |s|
      format = 0
      found = Guess.where(word: s.word, game_id: session['game_id'])
      unless found.empty?
        if found.find_by(user_id: current_user.id)
          if found.count == 1
            # no one but Player found the word
            format = 3
          else
            # Player and others found the word
            format = 2
          end
        else
          # other Player found the word
          format = 1
        end
      end
      @tpoints = @tpoints + letter_score[s.word.length]
      [s.word, s.word.length, letter_score[s.word.length], format]
    end
    @words.sort! do |a, b|
      if b[1] == a[1]
        a[0] <=> b[0]
      else
        b[1] <=> a[1]
      end
    end

    # Player score
    @twords = @words.length
    @cwords, @cpoints = get_score

    # All player's score
    @scores = ActiveRecord::Base.connection.execute(
      'SELECT a.id, a.guest, a.name, a.elo, count(b.points), sum(b.points)' +
      '  FROM guesses b' +
      '  JOIN users a' +
      '    ON a.id = b.user_id' +
      ' WHERE b.game_id = ' + session['game_id'].to_s +
      '   AND b.points > 0' +
      ' GROUP BY a.id ' +
      'HAVING SUM(b.points) > 0' +
      ' ORDER BY SUM(b.points) DESC')

    compute_highscore if @cpoints > 0
  end

  def guess
    word = params['words'].downcase
    if Solution.find_by(game_id: session['game_id'], word: word).nil?
      @guess = 0
    else
      @guess = letter_score[word.length]
    end
    if Guess.find_by(user_id: current_user.id, game_id: session['game_id'], word: word).nil?
      Guess.create(user_id: current_user.id, game_id: session['game_id'], word: word, points: @guess)
    else
      @guess = nil
    end
    @cwords, @cpoints = get_score
  end

  def sync
    # Most recent game is older than 215 seconds (180 game + 30 pause + 10 sync)
    time_left = get_time_left
    if time_left <= 0
      if Lock.find_by(lock: 2).nil?
        begin
          l = Lock.create
          g = Game.create
          l.destroy
        rescue
          # ignore unique index constraint violation and sync again
          # another player already computes the next game
        end
      else
        render inline: 'maintenance'
        return
      end
    end
    render inline: "#{time_left.to_i}"
  end

  def help
    @help = true
    @subtitle = 'Hilfe'
  end

  def highscore_elo
    @scores = highscore(' ORDER BY u.elo DESC, cpoints DESC, cwords DESC')
    render 'highscore', locals: { highscore_type: 'elo' }
  end

  def highscore_points
    @scores = highscore(' ORDER BY cpoints DESC, u.elo DESC, cwords DESC')
    render 'highscore', locals: { highscore_type: 'cpoints' }
  end

  def highscore_points_percent
    @scores = highscore(' ORDER BY ppoints DESC, u.elo DESC, cwords DESC')
    render 'highscore', locals: { highscore_type: 'ppoints' }
  end

  def highscore_words
    @scores = highscore(' ORDER BY cwords DESC, cpoints DESC, u.elo DESC')
    render 'highscore', locals: { highscore_type: 'cwords' }
  end

  def highscore_words_percent
    @scores = highscore(' ORDER BY pwords DESC, ppoints DESC, u.elo DESC')
    render 'highscore', locals: { highscore_type: 'pwords' }
  end

  def highscore(order_by)
    @help = true
    @canonical = 'http://spiele.sechzehn.org/highscore/elo'
    @which = params[:which]

    case @which
    when '3'
      # daily
      sql = 'SELECT u.id, u.name, u.elo, s.count as count, s.cwords as cwords, s.pwords as pwords, s.cpoints as cpoints, s.ppoints as ppoints' +
          '  FROM users u' +
          '  JOIN scores s' +
          '    ON u.id = s.user_id' +
          '   AND s.score_type = ' + Score.score_types[:daily].to_s +
          '   AND s.created_at >= \'' + Date.today.to_s + '\''

      @subtitle = 'Rangliste für ' + ['Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'][Date.today.wday]

    when '2'
      # weekly
      sql = 'SELECT u.id, u.name, u.elo, sum(s.count) as count, sum(s.cwords*s.count)/sum(s.count) as cwords, sum(s.pwords*s.count)/sum(s.count) as pwords, sum(s.cpoints*s.count)/sum(s.count) as cpoints, sum(s.ppoints*s.count)/sum(s.count) as ppoints' +
          '  FROM users u' +
          '  JOIN scores s' +
          '    ON u.id = s.user_id' +
          '   AND s.score_type = ' + Score.score_types[:daily].to_s +
          '   AND s.created_at >= \'' + Date.today.beginning_of_week.to_s + '\'' +
          ' GROUP BY u.id, u.name, u.elo, s.user_id'

      @subtitle = 'Rangliste der ' + Date.today.cweek.to_s + '. KW'

    when '1'
      # monthly
      sql = 'SELECT u.id, u.name, u.elo, sum(s.count) as count, sum(s.cwords*s.count)/sum(s.count) as cwords, sum(s.pwords*s.count)/sum(s.count) as pwords, sum(s.cpoints*s.count)/sum(s.count) as cpoints, sum(s.ppoints*s.count)/sum(s.count) as ppoints' +
          '  FROM users u' +
          '  JOIN scores s' +
          '    ON u.id = s.user_id' +
          '   AND s.score_type = ' + Score.score_types[:daily].to_s +
          '   AND s.created_at >= \'' + Date.today.beginning_of_month.to_s + '\'' +
          ' GROUP BY u.id, u.name, u.elo, s.user_id'
      @subtitle = 'Rangliste für ' + ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'][Date.today.month-1]

    else
      # all time
      sql = 'SELECT u.id, u.name, u.elo, s.count as count, s.cwords as cwords, s.pwords as pwords, s.cpoints as cpoints, s.ppoints as ppoints' +
          '  FROM users u' +
          '  JOIN scores s' +
          '    ON u.id = s.user_id' +
          '   AND s.score_type = ' + Score.score_types[:all_time].to_s
      @which = '0'
      @subtitle = 'ewige Rangliste'

    end
    sql = sql + order_by
    ActiveRecord::Base.connection.execute(sql)
  end

  def maintenance
    render 'layouts/maintenance'
  end

  def error_404
    @subtitle = 'Seite nicht gefunden - 404'
    respond_to do |format|
      format.html { render status: 404 }
      format.any  { render text: "404 Not found", status: 404 }
    end
  end

  def error_422
    @subtitle = 'Die Verarbeitung der Anfrage wurde abgelehnt (422)'
    respond_to do |format|
      format.html { render status: 422 }
      format.any  { render text: "422 Unprocessable Entity", status: 422 }
    end
  end

  def error_500
    @subtitle = 'Unerwarteter Systemfehler (500)'
    respond_to do |format|
      format.html { render status: 500 }
      format.any  { render text: "500 Internal Server Error", status: 500 }
    end
  end

  private

    def letter_score
      [0, 0, 0, 1, 1, 2, 3, 5, 11, 11, 11, 11, 11, 11, 11, 11, 11]
    end

    def init_field
      if session['game_id']
        letters = Game.find_by(id: session['game_id']).letters
      else
        letters = 'RPOESECHZEHNDTEE'
      end
      [
        [['nw', letters[0]], ['', letters[1]], ['', letters[2]], ['ne', letters[3]]],
        [['', letters[4]], ['', letters[5]], ['', letters[6]], ['', letters[7]]],
        [['', letters[8]], ['', letters[9]], ['', letters[10]], ['', letters[11]]],
        [['sw', letters[12]], ['', letters[13]], ['', letters[14]], ['se', letters[15]]]
      ]
    end

    def get_score
      if signed_in?
        guesses = Guess.where("user_id = ? AND game_id = ? AND points > 0", current_user.id, session['game_id'])
        [guesses.count, guesses.sum(:points)]
      else
        [0, 0]
      end
    end

    def compute_highscore

      # cleanup
      Score.where("user_id=? and score_type=? and created_at<?", current_user.id, Score.score_types[:daily], Date.today-1.month).destroy_all

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

      if session['game_id'] != score.game_id and !session['game_id'].nil?
        score.cwords = (score.cwords * score.count + @cwords) / (score.count + 1)
        score.pwords = (score.pwords * score.count + (@cwords * 100 / @twords)) / (score.count + 1)
        score.cpoints = (score.cpoints * score.count + @cpoints) / (score.count + 1)
        score.ppoints = (score.ppoints * score.count + (@cpoints * 100 / @tpoints)) / (score.count + 1)
        score.count = score.count + 1
        score.game_id = session['game_id']

        score_daily.cwords = (score_daily.cwords * score_daily.count + @cwords) / (score_daily.count + 1)
        score_daily.pwords = (score_daily.pwords * score_daily.count + (@cwords * 100 / @twords)) / (score_daily.count + 1)
        score_daily.cpoints = (score_daily.cpoints * score_daily.count + @cpoints) / (score_daily.count + 1)
        score_daily.ppoints = (score_daily.ppoints * score_daily.count + (@cpoints * 100 / @tpoints)) / (score_daily.count + 1)
        score_daily.count = score_daily.count + 1
        score_daily.game_id = session['game_id']

        delta_elo = 0
        @scores.each do |s|
          if s['id'].to_i != score.user_id
            if s['sum'].to_i > 0
              r = s['elo'].to_f - current_user.elo.to_f
              r = ((r > 0) ? 400.0 : -400.0) if r.abs > 400.0
              ea = 1.0 / (1.0 + 10.0 ** (r / 400.0))
              delta_elo = delta_elo + k(score) * (sa(s['sum'].to_i) - ea)
            end
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

    def k(me)
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

    def get_time_left()
      game_id = Game.maximum(:id)
      220 - (Time.now - Game.find_by(id: game_id).created_at)
    end

end
