class CreateOnlineLocations < ActiveRecord::Migration
  def up
    execute " CREATE TABLE online_locations (
              license_state char(2) not null,
              license_country char(2) not null,
              FOREIGN KEY (license_state, license_country) REFERENCES states(iso, country_id)

    )"
  end

  def down
    execute " DROP TABLE online_locations"
  end
end
