class SechzehnController < ApplicationController

    def show

        @field = init_field
        @words = solve(@field)
    end

  private

    def init_field

      a = [
            [['nw', draw_letter], ['', draw_letter], ['', draw_letter], ['ne', draw_letter]],
            [['', draw_letter], ['', draw_letter], ['', draw_letter], ['', draw_letter]],
            [['', draw_letter], ['', draw_letter], ['', draw_letter], ['', draw_letter]],
            [['sw', draw_letter], ['', draw_letter], ['', draw_letter], ['se', draw_letter]],
          ]
    end

    def draw_letter

      case rand(10000)
        when 8260..9999 then 'E'
        when 7282..8259 then 'N'
        when 6527..7281 then 'I'
        when 5800..6526 then 'S'
        when 5100..5799 then 'R'
        when 4449..5099 then 'A'
        when 3834..4448 then 'T'
        when 3326..3833 then 'D'
        when 2850..3325 then 'H'
        when 2415..2849 then 'U'
        when 2071..2414 then 'L'
        when 1765..2070 then 'C'
        when 1464..1764 then 'G'
        when 1211..1463 then 'M'
        when 960..1210 then 'O'
        when 771..959 then 'B'
        when 582..770 then 'W'
        when 416..581 then 'F'
        when 295..415 then 'K'
        when 182..294 then 'Z'
        when 103..181 then 'P'
        when 36..102 then 'V'
        when 9..35 then 'J'
        when 5..8 then 'Y'
        when 1..4 then 'X'
        else 'Qu'
      end

    end

    def solve(f)



    end

end
