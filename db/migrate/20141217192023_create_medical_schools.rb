class CreateMedicalSchools < ActiveRecord::Migration
  def up
    execute " CREATE TABLE medical_schools (
              name varchar(255) PRIMARY KEY
    )
    "
  end

  def down
    execute " DROP TABLE medical_schools"
  end
end
