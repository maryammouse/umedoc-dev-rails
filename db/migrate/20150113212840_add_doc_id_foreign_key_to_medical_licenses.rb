class AddDocIdForeignKeyToMedicalLicenses < ActiveRecord::Migration
  def up
    execute " ALTER TABLE medical_licenses 
              ADD COLUMN doctor_id integer not null REFERENCES doctors(id)
    "
  end

  def down
    execute " ALTER TABLE medical_licenses
              DROP COLUMN doctor_id
    "
  end
end
