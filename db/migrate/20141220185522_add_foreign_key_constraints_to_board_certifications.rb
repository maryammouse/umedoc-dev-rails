class AddForeignKeyConstraintsToBoardCertifications < ActiveRecord::Migration
  def up
    execute " ALTER TABLE board_certifications
              ADD CONSTRAINT board_certifications_board_specialty_fkey FOREIGN KEY (board_name, specialty) REFERENCES specialty_member_boards (board, specialty)
    "
  end

  def down
    execute " ALTER TABLE board_certifications
              DROP CONSTRAINT board_certifications_board_specialty_fkey
    "
  end
end

