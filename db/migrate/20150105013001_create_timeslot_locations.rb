class CreateTimeslotLocations < ActiveRecord::Migration
  def up
    execute " 
            /* need to create the ID columns in each table first T__T */

              ALTER TABLE online_locations
              ADD COLUMN id SERIAL PRIMARY KEY;
              
              ALTER TABLE office_locations
              ADD COLUMN id SERIAL PRIMARY KEY;

              ALTER TABLE area_locations
              ADD COLUMN id SERIAL PRIMARY KEY;
    
              CREATE TABLE timeslot_locations (
              timeslot_id integer not null REFERENCES timeslots(id),
              online_location_id integer REFERENCES online_locations(id),
              area_location_id integer REFERENCES area_locations(id),
              office_location_id integer REFERENCES office_locations(id)
    )"
  end

  def down
    execute " DROP TABLE timeslot_locations"
  end
end
