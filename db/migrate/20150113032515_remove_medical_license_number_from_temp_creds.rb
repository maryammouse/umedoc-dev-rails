class RemoveMedicalLicenseNumberFromTempCreds < ActiveRecord::Migration
  def up
    execute " ALTER TABLE temporary_credentials 
              DROP COLUMN medical_license_number
    "
  end

  def down
    execute " ALTER TABLE temporary_credentials
              ADD COLUMN medical_license_number varchar(20) not null
    "
  end
end
