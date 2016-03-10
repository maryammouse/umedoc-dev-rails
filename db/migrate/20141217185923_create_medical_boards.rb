class CreateMedicalBoards < ActiveRecord::Migration
  def up
    execute " CREATE TABLE medical_boards (
              name varchar(255) PRIMARY KEY
            )"
  end

  def down
    execute " DROP TABLE medical_boards "
  end
end
