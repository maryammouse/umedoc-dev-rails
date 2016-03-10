class AddDoctorIdToBoardCertifications < ActiveRecord::Migration
  def up
    execute " ALTER TABLE board_certifications
              ADD COLUMN doctor_id integer NOT NULL REFERENCES doctors(id)
    "
  end

  def down
    execute " ALTER TABLE board_certifications
              DROP COLUMN doctor_id
    "
  end
end
