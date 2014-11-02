class Game < ActiveRecord::Base

  before_validation :roll_dice
  after_create :find_words
  has_many :solutions, dependent: :destroy
  has_many :guesses, dependent: :destroy

  validates :letters, presence: true

  private

    def roll_dice
      vowels = 0
      # at least two vowels, but not more than six
      until (2..6) === vowels
        self.letters = (0.upto(15).map { |i| draw_letter }).join
        vowels = self.letters.count('aeiou')
      end
    end

    def find_words
      @words = []
      @field = []

      0.upto(3) do |y|
        @field << []
        0.upto(3) do |x|
          @field[y][x] = [0, self.letters[y*4+x]]
        end
      end

      0.upto(3) do |y|
        0.upto(3) do |x|
          solve('', x, y)
        end
      end
      @words.uniq!
      ActiveRecord::Base.transaction do
        @words.each do |word|
          self.solutions.create(word: word)
        end
      end

      @words = nil
      @field = nil
      self.touch
    end

    def draw_letter

      # draw a letter according to its frequency of occurrence in German language.
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
      return if @field[y][x][0] == 1

      word = word + @field[y][x][1]

      # break, if no word starts with 'word%'
      return if Word.where("word >= '#{word}' AND word <= '#{word + 'zzzzzzzzzzzzzzz'}'").empty?

      # mark letter as used
      @field[y][x][0] = 1
      # only words longer than 2 letters are valid
      if word.length > 2
        # add word to solution if it can be found in the word list
        @words << word unless Word.find_by(word: word).nil?
      end

      # create words, using adjacent letters
      solve(word, x-1, y-1)
      solve(word, x, y-1)
      solve(word, x+1, y-1)
      solve(word, x-1, y)
      solve(word, x+1, y)
      solve(word, x-1, y+1)
      solve(word, x, y+1)
      solve(word, x+1, y+1)
      @field[y][x][0] = 0

    end

end
