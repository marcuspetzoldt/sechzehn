require 'benchmark'

class SechzehnController < ApplicationController

    def show

      @field = init_field
      @words = []
      0.upto(3) do |y|
        0.upto(3) do |x|
          solve('', x, y)
        end
      end
      @words.uniq!
      @words.sort! do |a, b|
        if b[1] == a[1]
          a[0] <=> b[0]
        else
          b[1] <=> a[1]
        end
      end

      # mark corner fields with special css class for rounded corner
      @field[0][0][0] = 'nw'
      @field[0][3][0] = 'ne'
      @field[3][0][0] = 'sw'
      @field[3][3][0] = 'se'

      @word_count = @words.length
      @word_points = 0
      @words.each do |word|
        @word_points = @word_points + word[2]
      end

    end

  private

    def letter_score
      [0, 0, 0, 1, 1, 2, 3, 5, 11, 11, 11, 11, 11, 11, 11, 11, 11]
    end

    def init_field

      a = [
            [['', draw_letter], ['', draw_letter], ['', draw_letter], ['', draw_letter]],
            [['', draw_letter], ['', draw_letter], ['', draw_letter], ['', draw_letter]],
            [['', draw_letter], ['', draw_letter], ['', draw_letter], ['', draw_letter]],
            [['', draw_letter], ['', draw_letter], ['', draw_letter], ['', draw_letter]]
          ]
    end

    def draw_letter

      case rand(10000)
        when 8260..9999 then 'e'
        when 7282..8259 then 'n'
        when 6527..7281 then 'i'
        when 5800..6526 then 's'
        when 5100..5799 then 'r'
        when 4449..5099 then 'a'
        when 3834..4448 then 't'
        when 3326..3833 then 'd'
        when 2850..3325 then 'h'
        when 2415..2849 then 'u'
        when 2071..2414 then 'l'
        when 1765..2070 then 'c'
        when 1464..1764 then 'g'
        when 1211..1463 then 'm'
        when 960..1210 then 'o'
        when 771..959 then 'b'
        when 582..770 then 'w'
        when 416..581 then 'f'
        when 295..415 then 'k'
        when 182..294 then 'z'
        when 103..181 then 'p'
        when 36..102 then 'v'
        when 9..35 then 'j'
        when 5..8 then 'y'
        when 1..4 then 'x'
        else 'qu'
      end

    end

    def solve(word, x, y)

      # break, if out of bounds
      return if x < 0
      return if x > 3
      return if y < 0
      return if y > 3

      # break, if letter already used
      return if @field[y][x][0] == '1'

      word = word + @field[y][x][1]

      # break, if no word starts with 'word%'
      return if Word.where("word >= '#{word}' AND word <= '#{word + 'zzzzzzzzzzzzzzz'}'").empty?

      # mark letter as used
      @field[y][x][0] = '1'
      # only words longer than 2 letters are valid
      if word.length > 2
        # break, if there are no words beginning with 'word%'
        # add word to solution if it can be found in the wordlist
        @words << [word, word.length, letter_score[word.length]] unless Word.find_by(word: word).nil?
      end

      solve(word, x-1, y-1)
      solve(word, x, y-1)
      solve(word, x+1, y-1)
      solve(word, x-1, y)
      solve(word, x+1, y)
      solve(word, x-1, y+1)
      solve(word, x, y+1)
      solve(word, x+1, y+1)
      @field[y][x][0] = ''

    end

end
