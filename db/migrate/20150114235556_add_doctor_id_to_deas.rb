class AddDoctorIdToDeas < ActiveRecord::Migration
  def up
    execute " ALTER TABLE deas
              ADD COLUMN doctor_id integer NOT NULL REFERENCES doctors(id)
    "
  end

  def down
    execute " ALTER TABLE deas
              DROP COLUMN doctor_id
    "
  end
end
