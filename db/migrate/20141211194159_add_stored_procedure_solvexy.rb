class AddStoredProcedureSolvexy < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE OR REPLACE FUNCTION solvexy(pid integer, pletters char(16), pword varchar(16), px integer, py integer) RETURNS integer AS $$
          DECLARE
            vxy INTEGER;
            vres INTEGER;
            vch CHAR(1);
          BEGIN
            -- out of bounds
            IF px < 0 OR px > 3 THEN RETURN 1; END IF;
            IF py < 0 OR py > 3 THEN RETURN 1; END IF;

            -- letter already used
            vxy := py * 4 + px;
            vch := SUBSTR(pletters, vxy+1, 1);
            IF vch = '0' THEN RETURN 1; END IF;

            -- mark used letter
            pletters := CONCAT(LEFT(pletters, vxy), '0', RIGHT(pletters, 15 - vxy));
            -- no words beginning with word
            pword := CONCAT(pword, vch);
            SELECT 1 INTO vres FROM words WHERE word BETWEEN pword AND pword || 'zzzzzzzzzzzzzzzz' LIMIT 1;
            IF NOT FOUND THEN RETURN 1; END IF;

            -- add word to solution if valid
            IF LENGTH(pword) > 2 THEN
                SELECT 1 INTO vres FROM solutions WHERE word = pword AND game_id = pid;
                IF NOT FOUND THEN
            INSERT INTO solutions (game_id, word) SELECT pid, word FROM words WHERE word = pword;
                END IF;
            END IF;

            -- build word with adjacent letters
            PERFORM solvexy(pid, pletters, pword, px+1, py+1);
            PERFORM solvexy(pid, pletters, pword, px, py+1);
            PERFORM solvexy(pid, pletters, pword, px-1, py+1);
            PERFORM solvexy(pid, pletters, pword, px+1, py);
            PERFORM solvexy(pid, pletters, pword, px-1, py);
            PERFORM solvexy(pid, pletters, pword, px+1, py-1);
            PERFORM solvexy(pid, pletters, pword, px, py-1);
            PERFORM solvexy(pid, pletters, pword, px-1, py-1);

            RETURN 1;
          END;
          $$ LANGUAGE plpgsql;
        SQL
      end
      dir.down do
        execute <<-SQL
          DROP FUNCTION solvexy(integer, char(16), varchar(16), integer, integer)
        SQL
      end
    end
  end
end
