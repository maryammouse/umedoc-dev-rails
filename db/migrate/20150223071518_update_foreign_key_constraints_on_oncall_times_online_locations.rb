class UpdateForeignKeyConstraintsOnOncallTimesOnlineLocations < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table oncall_times_online_locations
        drop constraint if exists oncall_times_online_locations_oncall_time_id_fkey,
        drop constraint if exists oncall_times_online_locations_online_location_id_fkey,
        add foreign key (oncall_time_id) references oncall_times(id) on delete cascade,
        add foreign key (online_location_id) references online_locations(id) on delete restrict;

                SQL
  end

  def down
    execute  <<-SQL
      alter table oncall_times_online_locations
        drop constraint if exists oncall_times_online_locations_oncall_time_id_fkey,
        drop constraint if exists oncall_times_online_locations_online_location_id_fkey,
        add foreign key (oncall_time_id) references oncall_times(id) on delete restrict,
        add foreign key (online_location_id) references online_locations(id) on delete restrict;

                SQL
  end

end
