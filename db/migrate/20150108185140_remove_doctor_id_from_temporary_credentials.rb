class RemoveDoctorIdFromTemporaryCredentials < ActiveRecord::Migration
  def up
    execute " ALTER TABLE temporary_credentials
              DROP CONSTRAINT temporary_credentials_doctor_id_fkey,
              DROP COLUMN doctor_id

    "
  end

  def down
    execute " ALTER TABLE temporary_credentials
              ADD COLUMN doctor_id REFERENCES doctors(id)
    "
  end
end
