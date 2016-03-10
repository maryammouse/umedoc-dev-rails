class DocIdToMalpractices < ActiveRecord::Migration
  def up
    execute " ALTER TABLE malpractices
              ADD COLUMN doctor_id integer not null REFERENCES doctors(id)
    "
  end

  def down
    execute " ALTER TABLE malpractices
              DROP COLUMN malpractices
    "
  end
end
