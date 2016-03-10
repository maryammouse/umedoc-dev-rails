class CreateVisitOnlineLocations < ActiveRecord::Migration
  def up
    execute " CREATE TABLE visits_online_locations(
              visit_id integer NOT NULL REFERENCES visits(id),
              online_location_id integer NOT NULL REFERENCES online_locations(id),
              id serial PRIMARY KEY

    )"
  end
  def down
    execute " DROP TABLE IF EXISTS visits_online_locations;"
  end
end
