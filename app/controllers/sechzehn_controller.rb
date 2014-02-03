class SechzehnController < ApplicationController

    def new
      game_id = Game.maximum(:id)
      if game_id != session['game_id']
        # start a new game
        current_user.guesses.destroy_all if signed_in?
        current_user.update_attribute(:elo, current_user.new_elo)
        session['game_id'] = Game.maximum(:id)
        response.headers['X-Refreshed'] = '0'
      else
        # continue a game
        response.headers['X-Refreshed'] = '1'
      end
      @field = init_field
      render partial: 'layouts/show_dice'
    end

    def show
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
        'SELECT a.id, a.name, a.elo, count(b.points), sum(b.points)' +
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
        @guess = [word, 0]
      else
        @guess = [word, letter_score[word.length]]
      end
      if Guess.find_by(user_id: current_user.id, game_id: session['game_id'], word: word).nil?
        Guess.create(user_id: current_user.id, game_id: session['game_id'], word: word, points: @guess[1])
      else
        @guess = []
      end
      @cwords, @cpoints = get_score
    end

    def sync
      game_id = Game.maximum(:id)
      time_left = 220 - get_time_left(game_id)
      # Most recent game is older than 215 seconds (180 game + 30 pause + 10 sync)
      if time_left <= 0
        begin
          l = Lock.create
          g = Game.create
          l.destroy
        rescue
          # ignore unique index constraint violation and sync again
          # another player already computes the next game
          sleep(0.5)
        end
      end
      render inline: "#{time_left.to_i}"
    end

    def help
      @help = true
    end

    def highscore
      @help = true
      @scores = ActiveRecord::Base.connection.execute(
          'SELECT u.name, u.elo, s.count, s.cwords, s.pwords, s.cpoints, s.ppoints' +
          '  FROM users u' +
          '  JOIN scores s' +
          '    ON u.id = s.user_id' +
          '   AND s.score_type = ' + Score.score_types[:all_time].to_s +
          ' ORDER BY u.elo desc, s.cpoints desc, s.cwords desc'
      )
    end

  private

    def letter_score
      [0, 0, 0, 1, 1, 2, 3, 5, 11, 11, 11, 11, 11, 11, 11, 11, 11]
    end

    def init_field
      if session['game_id']
        letters = Game.find_by(id: session['game_id']).letters
      else
        letters = 'XXXXXXXXXXXXXXXX'
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
      if signed_in?
        begin
          score = Score.find_by!(user_id: current_user.id, score_type: Score.score_types[:all_time] )
        rescue ActiveRecord::RecordNotFound
          score = Score.new(user_id: current_user.id, game_id: 0, score_type: Score.score_types[:all_time], count: 0, cwords: 0, pwords: 0, cpoints: 0, ppoints: 0)
        end

        if session['game_id'] != score.game_id and !session['game_id'].nil?
          score.cwords = (score.cwords * score.count + @cwords) / (score.count + 1)
          score.pwords = (score.pwords * score.count + (@cwords * 100 / @twords)) / (score.count + 1)
          score.cpoints = (score.cpoints * score.count + @cpoints) / (score.count + 1)
          score.ppoints = (score.ppoints * score.count + (@cpoints * 100 / @tpoints)) / (score.count + 1)
          score.count = score.count + 1
          score.game_id = session['game_id']

          delta_elo = 0
          count = 0
          @scores.each do |s|
            if s['id'].to_i != score.user_id
              if s['sum'].to_i > 0
                count = count + 1
                r = s['elo'].to_i - current_user.elo
                r = (r > 0) ? 400 : -400 if r.abs > 400
                ea = 1.0 / (1 + 10 ** (r / 400))
                delta_elo = delta_elo + k(score) * (sa(s['sum'].to_i) - ea)
              end
            end
          end
          new_elo = current_user.elo + delta_elo / count if count > 0
          current_user.update_attribute(:new_elo, new_elo)
          score.save
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

    def get_time_left(game_id)
      Time.now - Game.find_by(id: game_id).created_at
    end
end
