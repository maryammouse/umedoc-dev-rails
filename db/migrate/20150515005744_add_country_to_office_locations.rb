class AddCountryToOfficeLocations < ActiveRecord::Migration
  def up
    execute " ALTER TABLE office_locations
              ADD COLUMN country text NOT NULL REFERENCES countries(iso)
    
    "
  end

  def down
    execute " ALTER TABLE office_locations
              DROP COLUMN country
    "
  end
end
