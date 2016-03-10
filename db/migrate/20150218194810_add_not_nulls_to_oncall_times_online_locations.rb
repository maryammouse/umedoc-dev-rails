class AddNotNullsToOncallTimesOnlineLocations < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table oncall_times_online_locations
        alter column oncall_time_id set not null,
        alter column online_location_id set not null;

                SQL
  end

  def down
    execute  <<-SQL
      alter table oncall_times_online_locations
        alter column oncall_time_id drop not null,
        alter column online_location_id drop not null;

                SQL
  end
end
