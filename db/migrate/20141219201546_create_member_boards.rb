class CreateMemberBoards < ActiveRecord::Migration
  def up
    execute " CREATE TABLE member_boards (
              name varchar(64) PRIMARY KEY
    )"
  end

  def down
    execute " DROP TABLE member_boards"
  end
end

