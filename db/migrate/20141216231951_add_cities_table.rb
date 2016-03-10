class AddCitiesTable < ActiveRecord::Migration
  def up
      execute " CREATE TABLE primary_cities (
                name varchar(32) PRIMARY KEY,
                zip_code char(5) REFERENCES zip_codes (zip)
                )
      "
  end
  def down
    execute " DROP TABLE primary_cities "
  end
end
