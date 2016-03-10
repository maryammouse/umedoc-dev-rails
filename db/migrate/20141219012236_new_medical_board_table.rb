class NewMedicalBoardTable < ActiveRecord::Migration
  def change
    execute " ALTER TABLE medical_board_states
              DROP constraint medical_board_states_name_fkey
              "
    execute " DROP TABLE medical_boards"
    execute " ALTER TABLE medical_board_states
              RENAME to medical_boards
              "
  end
end
