class AddConstraintsToMedicalDegrees < ActiveRecord::Migration
  def change
    execute " ALTER TABLE medical_degrees
              ADD CONSTRAINT degree_type_within CHECK (degree_type in ('Medical Degree - Allopathic',
                                                                       'Medical Degree - Osteopathic'))
    "
  end

  def down
    execute " ALTER TABLE medical_degrees
              DROP CONSTRAINT degree_type_within"
  end
end
