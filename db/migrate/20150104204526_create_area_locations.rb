class CreateAreaLocations < ActiveRecord::Migration
  def up
    execute " CREATE TABLE area_locations (
              zipcode char(5) not null REFERENCES zip_codes(zip)
    )"
  end

  def down
    execute " DROP TABLE area_locations"
  end
end
