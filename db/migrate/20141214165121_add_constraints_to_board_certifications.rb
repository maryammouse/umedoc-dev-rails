class AddConstraintsToBoardCertifications < ActiveRecord::Migration
  def up
    execute " ALTER TABLE board_certifications
              ADD CONSTRAINT board_name_length CHECK (char_length(board_name) <= 64 ),
              ADD CONSTRAINT specialty_length CHECK (char_length(specialty) <= 64)
              "
  end

  def down
    execute " ALTER TABLE board_certifications
              DROP CONSTRAINT board_name_length,
              DROP CONSTRAINT specialty_length
            "
  end
end
