class AddCertificationNumberToBoardCertification < ActiveRecord::Migration
  def change
    add_column :board_certifications, :certification_number, :string
  end
end
