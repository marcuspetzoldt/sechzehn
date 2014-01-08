class SechzehnController < ApplicationController

    def new
      Guess.destroy(Guess.where(user_id: 1))
      session['game_id'] = Game.maximum(:id)
      @field = init_field
      render 'show'
    end

    def show
      @field = init_field
    end

    def solution
      # TODO tag words with 'found by: [noone, you, only you, other]'
      @words = Game.find(session['game_id']).solutions.map { |s| [s.word, s.word.length, letter_score[s.word.length]] }
      @words.sort! do |a, b|
        if b[1] == a[1]
          a[0] <=> b[0]
        else
          b[1] <=> a[1]
        end
      end

      @word_count = @words.length
      @word_points = 0
      @words.each do |word|
        @word_points = @word_points + word[2]
      end
    end

    def guess
      word = params['words'].downcase
      if Solution.find_by(game_id: session['game_id'], word: word).nil?
        @guess = [word, 0]
      else
        @guess = [word, letter_score[word.length]]
      end
      if Guess.find_by(user_id: 1, game_id: session['game_id'], word: word).nil?
        # TODO replace dummy user_id with correct user_id from database
        Guess.create(user_id: 1, game_id: session['game_id'], word: word)
      else
        @guess = nil
      end
    end

  private

    def letter_score
      [0, 0, 0, 1, 1, 2, 3, 5, 11, 11, 11, 11, 11, 11, 11, 11, 11]
    end

    def init_field
      letters = Game.find(session['game_id']).letters
      [
        [['nw', letters[0]], ['', letters[1]], ['', letters[2]], ['ne', letters[3]]],
        [['', letters[4]], ['', letters[5]], ['', letters[6]], ['', letters[7]]],
        [['', letters[8]], ['', letters[9]], ['', letters[10]], ['', letters[11]]],
        [['sw', letters[12]], ['', letters[13]], ['', letters[14]], ['se', letters[15]]]
      ]
    end

end
