class RenameNameToSpecialtyInSpecialtyMemberBoards < ActiveRecord::Migration
  def change
    rename_column :specialty_member_boards, :name, :specialty
  end
end
