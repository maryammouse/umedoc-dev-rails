class RenameMedicalBoardToStateMedicalBoard < ActiveRecord::Migration
  def up
    execute " ALTER TABLE medical_boards
              RENAME to state_medical_boards"
  end

  def down
    execute " ALTER TABLE state_medical_boards
              RENAME to medical_boards"
  end
end
