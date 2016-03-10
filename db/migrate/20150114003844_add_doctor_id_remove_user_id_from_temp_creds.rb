class AddDoctorIdRemoveUserIdFromTempCreds < ActiveRecord::Migration
  def up
    execute " ALTER TABLE temporary_credentials
              DROP COLUMN user_id,
              ADD COLUMN doctor_id integer NOT NULL REFERENCES doctors(id)
    "
  end

  def down
    execute " ALTER TABLE temporary_credentials
              DROP COLUMN doctor_id,
              ADD COLUMN user_id integer NOT NULL REFERENCES users(id)
    "
  end
end
