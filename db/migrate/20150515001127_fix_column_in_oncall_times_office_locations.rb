class FixColumnInOncallTimesOfficeLocations < ActiveRecord::Migration
  def up
    execute " ALTER TABLE oncall_times_office_locations 
              DROP COLUMN office_locations_id,
              ADD COLUMN office_location_id integer REFERENCES office_locations(id)
    "
  end

  def down
    execute " ALTER TABLE oncall_times_office_locations
              DROP COLUMN office_location_id,
              ADD COLUMN office_locations_id integer REFERENCES office_locations(id)
    "
  end
end
