class RemoveAndAddLicenseToTempCreds < ActiveRecord::Migration
  def up
    execute " ALTER TABLE temporary_credentials 
              ADD COLUMN medical_license_number varchar(255) not null,
              DROP COLUMN license_number,
              ADD COLUMN license_number varchar(20) not null
    "
  end

  def down
    execute " ALTER TABLE temporary_credentials
              DROP COLUMN license_number,
              DROP COLUMN medical_license_number varchar(255) not null
    "
  end
end
