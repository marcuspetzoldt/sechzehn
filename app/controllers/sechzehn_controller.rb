class SechzehnController < ApplicationController

    def new
      current_user.guesses.destroy_all if signed_in?
      session['game_id'] = Game.maximum(:id)
      @field = init_field
      render partial: 'layouts/show_dice'
    end

    def show
      @play = true
      session['game_id'] = Game.maximum(:id)
      if signed_in?
        @user = current_user
        if params[:what]
          @play = false
        end
      else
        @user = User.new
        @play = false
      end
      @field = init_field
    end

    def solution
      @words = Game.find_by(id: session['game_id']).solutions.map do |s|
        format = 0
        found = Guess.where(word: s.word)
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
      @tpoints = 0
      @words.each do |word|
        @tpoints = @tpoints + word[2]
      end
      @cwords, @cpoints = get_score

      # All player's score
    @scores = ActiveRecord::Base.connection.execute(
        'SELECT a.id, a.name, count(b.points), sum(b.points)' +
        '  FROM guesses b' +
        '  JOIN users a' +
        '    ON a.id = b.user_id' +
          ' WHERE b.game_id = ' + session['game_id'].to_s +
          '   AND b.points > 0' +
          ' GROUP BY a.id ' +
          'HAVING SUM(b.points) > 0' +
          ' ORDER BY SUM(b.points)')

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
        @guess = nil
      end
      @cwords, @cpoints = get_score
    end

    def sync
      time_left = 213 - get_time_left
      # Most recent game is older than 210 seconds
      if time_left <= 0
        begin
          Lock.create
          Game.create
          Lock.destroy_all
        rescue
          sleep 0.5 while Lock.uncached { Lock.find_by(lock: 1) }
        end
        time_left = 213
      end
      render inline: "#{time_left.to_i}"
    end

  private

    def letter_score
      [0, 0, 0, 1, 1, 2, 3, 5, 11, 11, 11, 11, 11, 11, 11, 11, 11]
    end

    def init_field
      letters = Game.find_by(id: session['game_id']).letters
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
      end
    end

    def get_time_left
      Time.now - Game.find_by(id: session['game_id']).created_at
    end

end
