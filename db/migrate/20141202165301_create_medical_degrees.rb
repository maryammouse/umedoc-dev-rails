class CreateMedicalDegrees < ActiveRecord::Migration
  def change
    create_table :medical_degrees do |t|
      t.string :degree_type
      t.string :awarded_by
      t.date :first_issued_date

      t.timestamps
    end
  end
end
