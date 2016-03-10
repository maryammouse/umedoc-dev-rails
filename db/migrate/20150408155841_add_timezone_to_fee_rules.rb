class AddTimezoneToFeeRules < ActiveRecord::Migration
  def up
    execute  <<-SQL


      CREATE EXTENSION IF NOT EXISTS citext;

      CREATE OR REPLACE FUNCTION is_timezone( tz TEXT ) RETURNS BOOLEAN as $$
        BEGIN
         PERFORM now() AT TIME ZONE tz;
         RETURN TRUE;
        EXCEPTION WHEN invalid_parameter_value THEN
         RETURN FALSE;
        END;
        $$ language plpgsql STABLE;

      DROP DOMAIN if exists timezone;
      CREATE DOMAIN timezone AS CITEXT
          CHECK ( is_timezone( value ) );

      DROP TABLE if exists tzone;
      CREATE TABLE tzone
      (
        tzone_name text PRIMARY KEY CHECK (is_timezone(tzone_name))
      );

      INSERT INTO tzone (tzone_name)
      SELECT name FROM pg_timezone_names;


      alter table fee_rules
        add column time_zone text
          not null
          default 'UTC'
          references tzone(tzone_name);

                SQL
  end

  def down
    execute  <<-SQL

      alter table fee_rules
        drop column time_zone;

      drop table if exists tzone;

      drop domain if exists timezone;

      drop function if exists is_timezone();

      drop extension if exists citext;

                SQL
  end
end
