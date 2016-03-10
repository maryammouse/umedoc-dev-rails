class AddAppropriateForeignKeyBehaviorToOncallTimesOfficeLocations < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table oncall_times_office_locations
        drop constraint if exists "oncall_times_office_locations_office_location_id_fkey",
        drop constraint if exists "oncall_times_office_locations_oncall_time_id_fkey",
        add constraint oncall_times_office_locations_office_location_id_fkey foreign key (office_location_id) references office_locations(id) on delete restrict,
        add constraint oncall_times_office_locations_oncall_time_id_fkey foreign key (oncall_time_id) references oncall_times(id) on delete cascade;

                SQL
  end

  def down
    execute  <<-SQL
      alter table oncall_times_office_locations
        drop constraint if exists "oncall_times_office_locations_office_location_id_fkey",
        drop constraint if exists "oncall_times_office_locations_oncall_time_id_fkey",
        add constraint oncall_times_office_locations_office_location_id_fkey foreign key (office_location_id) references office_locations(id),
        add constraint oncall_times_office_locations_oncall_time_id_fkey foreign key (oncall_time_id) references oncall_times(id);

                SQL
  end
end
