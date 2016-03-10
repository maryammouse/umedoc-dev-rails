class AddUniquenessConstraintsToSpecialtyMemberBoards < ActiveRecord::Migration
  def up
    execute " ALTER TABLE specialty_member_boards
              ADD CONSTRAINT uniqueness UNIQUE (specialty, board)
    "
  end
  def down
    execute " ALTER TABLE specialty_member_boards
              DROP CONSTRAINT uniqueness"
  end
end
