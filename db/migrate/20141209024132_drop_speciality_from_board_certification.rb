class DropSpecialityFromBoardCertification < ActiveRecord::Migration
  def change
    remove_column :board_certifications, :speciality
  end
end
