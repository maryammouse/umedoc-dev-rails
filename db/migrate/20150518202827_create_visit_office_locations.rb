class CreateVisitOfficeLocations < ActiveRecord::Migration
  def up
    execute " CREATE TABLE visits_office_locations(
              visit_id integer NOT NULL REFERENCES visits(id),
              office_location_id integer NOT NULL REFERENCES office_locations(id),
              id integer PRIMARY KEY


    )"
  end

  def down
    execute " DROP TABLE IF EXISTS visits_office_locations;"
  end
end
