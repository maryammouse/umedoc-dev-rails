class AddNotNullConstraintsToMedicalDegrees < ActiveRecord::Migration
  def change
    execute " ALTER TABLE medical_degrees
              ALTER COLUMN degree_type SET NOT NULL,
              ALTER COLUMN awarded_by SET NOT NULL,
              ALTER COLUMN date_awarded SET NOT NULL
    "
  end

  def down
    execute " ALTER TABLE medical_degrees
              ALTER COLUMN degree_type DROP NOT NULL,
              ALTER COLUMN awarded_by DROP NOT NULL,
              ALTER COLUMN date_awarded DROP NOT NULL
    "
  end
end
