class AddNotNullConstraintsToMedicalLicenses < ActiveRecord::Migration
  def up
    execute " ALTER TABLE medical_licenses
              ALTER COLUMN awarded_by SET NOT NULL,
              ALTER COLUMN license_number SET NOT NULL,
              ALTER COLUMN valid_in SET NOT NULL,
              ALTER COLUMN first_issued_date SET NOT NULL,
              ALTER COLUMN expiry_date SET NOT NULL
    "
  end

  def down
    execute " ALTER TABLE medical_licenses
              ALTER COLUMN awarded_by DROP NOT NULL,
              ALTER COLUMN license_number DROP NOT NULL,
              ALTER COLUMN valid_in DROP NOT NULL,
              ALTER COLUMN first_issued_date DROP NOT NULL,
              ALTER COLUMN expiry_date SET NOT NULL
    "
  end

end


