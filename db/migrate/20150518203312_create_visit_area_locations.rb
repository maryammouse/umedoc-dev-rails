class CreateVisitAreaLocations < ActiveRecord::Migration
  def up
    execute " CREATE TABLE visits_area_locations(
              visit_id integer NOT NULL REFERENCES visits(id),
              area_location_id integer NOT NULL REFERENCES area_locations(id),
              id integer PRIMARY KEY


    )"
  end

  def down
    execute " DROP TABLE IF EXISTS visits_area_locations;"
  end
end
