class FixMedicalDegreeColumnName < ActiveRecord::Migration
  def change
    rename_column :medical_degrees, :first_issued_date, :date_awarded
  end
end
