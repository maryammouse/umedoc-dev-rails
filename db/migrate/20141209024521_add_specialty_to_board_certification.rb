class AddSpecialtyToBoardCertification < ActiveRecord::Migration
  def change
    add_column :board_certifications, :specialty, :string
  end
end
