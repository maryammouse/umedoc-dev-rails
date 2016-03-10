class CreateMedicalLicenses < ActiveRecord::Migration
  def change
    create_table :medical_licenses do |t|
      t.string :awarded_by
      t.string :license_number
      t.string :valid_in
      t.date :first_issued_date
      t.date :expiry_date

      t.timestamps
    end
  end
end
