class AddDegreeTypeToMedicalSchools < ActiveRecord::Migration
  def up
    execute " ALTER TABLE medical_schools
              ADD COLUMN degree_type varchar(32) NOT NULL CHECK (degree_type in 
              ('Allopathic', 'Osteopathic'))
    "
  end

  def down
    execute " ALTER TABLE medical_schools
              DROP COLUMN degree_type
    "
  end
end
