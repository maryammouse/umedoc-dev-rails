class MakeColumnNamesSingularOnOncallTimesOnlineLocations < ActiveRecord::Migration

  def up
    execute  <<-SQL
      alter table oncall_times_online_locations
        drop column oncall_times_id,
        drop column online_locations_id,
        add column oncall_time_id integer references oncall_times(id),
        add column online_location_id integer references online_locations(id);

                SQL
  end

  def down
    execute  <<-SQL
      alter table oncall_times_online_locations
        drop column oncall_time_id,
        drop column online_location_id,
        add column oncall_times_id integer references oncall_times(id),
        add column online_locations_id integer references online_locations(id);

                SQL
  end
end
