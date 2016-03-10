class CreateSpecialtyMemberBoards < ActiveRecord::Migration
  def up
    create_table :specialty_member_boards

    execute " ALTER TABLE specialty_member_boards
              ADD COLUMN name varchar(64) NOT NULL REFERENCES specialties (name),
              ADD COLUMN board varchar(64) NOT NULL REFERENCES member_boards (name)
    "
  end

  def down
    execute " DROP TABLE specialty_member_boards"
  end
end
