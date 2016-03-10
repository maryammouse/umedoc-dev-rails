ActiveRecord::Base.connection.execute(
<<SQL
      INSERT INTO tzone (tzone_name)
      SELECT name FROM pg_timezone_names;
SQL
)
