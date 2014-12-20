class Game < ActiveRecord::Base

  before_validation :roll_dice
  after_create :find_words
  has_many :solutions, dependent: :destroy
  has_many :guesses, dependent: :destroy
  has_many :chats, dependent: :destroy

  validates :letters, presence: true

  private

    def roll_dice
      Rails.logger.info('GAMECREATION: Roll Dice Start')
      vowels = 0
      n = 0
      # at least two vowels, but not more than six
      until (2..6) === vowels
        self.letters = (0.upto(15).map { draw_letter }).join
        vowels = self.letters.count('aeiou')
        n = n + 1
      end
      self.letters = 'rpoesechqehndtee'
      Rails.logger.info("GAMECREATION: Roll Dice End after #{n} tries")
    end

    def find_words
      Rails.logger.info('GAMECREATION: Solve Start')
      Game.connection.execute("SELECT solve(#{self.id}, '#{self.letters}')")
      self.touch
      Rails.logger.info('GAMECREATION: Solve End')
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

end
