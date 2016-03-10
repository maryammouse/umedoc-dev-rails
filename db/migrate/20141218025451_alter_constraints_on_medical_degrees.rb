class AlterConstraintsOnMedicalDegrees < ActiveRecord::Migration
  def up
    execute " ALTER TABLE medical_degrees
              DROP CONSTRAINT degree_type_within,
              ADD CONSTRAINT degree_type_within CHECK (degree_type in ('Allopathic', 'Osteopathic'))
    "
  end

  def down
    execute " ALTER TABLE medical_degrees
              DROP CONSTRAINT degree_type_within,
              ADD CONSTRAINT degree_type_within CHECK (degree_type in ('Medical Degree - Allopathic',
                                                                      'Medical Degree - Osteopathic'))
    "
  end
end
