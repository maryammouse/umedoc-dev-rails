class AddWeeksAheadToFeeScheduleAndUpdatePgFunctions < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table fee_schedules 
        add column weeks_ahead
          integer
          not null
          default 4
          check (weeks_ahead >= 4);
                SQL


    file_path = Rails.root + 'db/functions/umedoc_functions.pgsql'
    if File.exists?(file_path) and File.readable?(file_path)
      if File.size(file_path) > 1000000
        puts "File size > 1000000, may cause slow performance when being loaded"
      end
      code_file = File.read(file_path)
      execute code_file
      execute <<-SQL
        update fee_schedules set weeks_ahead=4;
      SQL
    else
      puts "No readable file found to load postgres functions"
    end

  end

  def down
    execute  <<-SQL
      alter table fee_schedules 
        drop column if exists weeks_ahead;
                SQL
      puts "This down migration is unable to reverse the effect of loading pg functions"
  end
end
