class CreateOfficeLocations < ActiveRecord::Migration
  def up
    execute " CREATE TABLE office_locations (
              street_address_1 varchar(64) not null,
              street_address_2 varchar(64),
              city varchar(32) not null,
              state char(2) not null,
              zip_code char(5) not null
    )"
  end

  def down
    execute " DROP TABLE office_locations"
  end
end
