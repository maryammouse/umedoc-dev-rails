class RemoveDegreeTypeFromMedicalSchools < ActiveRecord::Migration
  def change
    remove_column :medical_schools, :degree_type
  end
end
