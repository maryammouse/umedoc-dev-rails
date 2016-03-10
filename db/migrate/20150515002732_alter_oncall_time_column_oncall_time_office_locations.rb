class AlterOncallTimeColumnOncallTimeOfficeLocations < ActiveRecord::Migration
  def up
    execute " ALTER TABLE oncall_times_office_locations
              DROP COLUMN oncall_times_id,
              ADD COLUMN oncall_time_id integer NOT NULL REFERENCES oncall_times(id),
              ALTER COLUMN office_location_id SET NOT NULL
    "
  end

  def down
    execute " ALTER TABLE oncall_times_office_locations
              DROP COLUMN oncall_time_id,
              ADD COLUMN oncall_times_id integer NOT NULL REFERENCES oncall_times(id),
              ALTER COLUMN office_location_id DROP NOT NULL
    "
  end
end
