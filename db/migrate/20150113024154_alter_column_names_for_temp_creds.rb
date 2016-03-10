class AlterColumnNamesForTempCreds < ActiveRecord::Migration
  def up
    execute " ALTER TABLE temporary_credentials
              RENAME COLUMN state_medical_board_name to awarded_by;

              ALTER TABLE temporary_credentials
              RENAME COLUMN medical_license_number to license_number
    "
  end

  def down
    execute " ALTER TABLE temporary_credentials
              RENAME COLUMN awarded_by to state_medical_board_name;

              ALTER TABLE temporary_credentials
              RENAME COLUMN license_number to medical_license_number
    "
  end
end
