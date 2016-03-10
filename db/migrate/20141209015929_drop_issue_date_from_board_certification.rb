class DropIssueDateFromBoardCertification < ActiveRecord::Migration
  def change
    remove_column :board_certifications, :date_awarded
  end
end
