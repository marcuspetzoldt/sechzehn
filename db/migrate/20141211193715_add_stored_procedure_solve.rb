class AddStoredProcedureSolve < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE OR REPLACE FUNCTION solve(pid integer, pletters char(16)) RETURNS integer AS $$
          DECLARE
          BEGIN
            PERFORM solvexy(pid, pletters, '', 0, 0);
            PERFORM solvexy(pid, pletters, '', 1, 0);
            PERFORM solvexy(pid, pletters, '', 2, 0);
            PERFORM solvexy(pid, pletters, '', 3, 0);
            PERFORM solvexy(pid, pletters, '', 0, 1);
            PERFORM solvexy(pid, pletters, '', 1, 1);
            PERFORM solvexy(pid, pletters, '', 2, 1);
            PERFORM solvexy(pid, pletters, '', 3, 1);
            PERFORM solvexy(pid, pletters, '', 0, 2);
            PERFORM solvexy(pid, pletters, '', 1, 2);
            PERFORM solvexy(pid, pletters, '', 2, 2);
            PERFORM solvexy(pid, pletters, '', 3, 2);
            PERFORM solvexy(pid, pletters, '', 0, 3);
            PERFORM solvexy(pid, pletters, '', 1, 3);
            PERFORM solvexy(pid, pletters, '', 2, 3);
            PERFORM solvexy(pid, pletters, '', 3, 3);
            RETURN 1;
          END;
          $$ LANGUAGE plpgsql;
        SQL
      end
      dir.down do
        execute <<-SQL
          DROP FUNCTION solve(integer, char(16))
        SQL
      end
    end
  end
end
