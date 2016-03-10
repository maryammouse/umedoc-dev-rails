class AddConstraintsToMedicalLicenses < ActiveRecord::Migration
  def up
    execute " ALTER TABLE medical_licenses
              ADD CONSTRAINT license_number_length CHECK (char_length(license_number) <= 20),
              ADD CONSTRAINT valid_in_length CHECK (char_length(valid_in) <= 2)
    "
  end

  def down
    execute " ALTER TABLE medical_licenses
              DROP CONSTRAINT license_number_length,
              DROP CONSTRAINT valid_in_length
    "
  end
end
