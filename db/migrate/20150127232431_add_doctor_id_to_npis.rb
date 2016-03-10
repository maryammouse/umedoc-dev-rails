class AddDoctorIdToNpis < ActiveRecord::Migration
  def up
    execute " ALTER TABLE npis
              ADD COLUMN doctor_id integer NOT NULL REFERENCES doctors(id)
    "
  end

  def down
    execute " ALTER TABLE npis
              DROP COLUMN doctor_id
    "
  end
end
