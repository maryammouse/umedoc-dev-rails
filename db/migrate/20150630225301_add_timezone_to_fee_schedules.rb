class AddTimezoneToFeeSchedules < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table fee_schedules
        add column time_zone text
          not null
          default 'US/Pacific'
          references tzone(tzone_name);

      alter table fee_rules
        drop column if exists time_zone;

                SQL

    # reload umedoc_functions, which has been updated to used time_zone from fee_schedule
    file_path = Rails.root + 'db/functions/umedoc_functions.pgsql'
    if File.exists?(file_path) and File.readable?(file_path)
      if File.size(file_path) > 1000000
        puts "File size > 1000000, may cause slow performance when being loaded"
      end
      code_file = File.read(file_path)
      execute code_file
    else
      puts "No readable file found to load postgres functions"
    end
  end

  def down
    execute  <<-SQL

      alter table fee_schedules
        drop column time_zone;

      alter table fee_rules
        add column time_zone text
          not null
          default 'UTC'
          references tzone(tzone_name);

                SQL
      puts "NOTICE: this migration does NOT rollback the state of umedoc_functions.pgsql"
  end
end
