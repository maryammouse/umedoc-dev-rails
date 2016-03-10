class MakeIdSerialForVisitsOfficeLocations < ActiveRecord::Migration
  def up
    execute " ALTER TABLE visits_office_locations
              DROP COLUMN IF EXISTS id,
              ADD COLUMN id serial PRIMARY KEY
    "
  end

  def down
    execute " ALTER TABLE visits_office_locations 
              DROP COLUMN IF EXISTS id,
              ADD COLUMN id integer PRIMARY KEY
    "
  end
end
