class AddNotNullConstraintsToMedicalBoards < ActiveRecord::Migration
  def up
    execute " ALTER TABLE medical_boards
              ALTER COLUMN state SET NOT NULL,
              ALTER COLUMN country SET NOT NULL"
  end

  def down
    execute " ALTER TABLE medical_boards
              ALTER COLUMN state DROP NOT NULL,
              ALTER COLUMN country DROP NOT NULL"
  end
end
