class CreateSpecialties < ActiveRecord::Migration
  def up
    execute " CREATE TABLE specialties (
              name varchar(64) PRIMARY KEY
              )"
  end
  def down
    execute " DROP TABLE specialties"
  end
end
