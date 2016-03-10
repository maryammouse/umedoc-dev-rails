class AddExpiryDateToBoardCertification < ActiveRecord::Migration
  def change
    add_column :board_certifications, :expiry_date, :date
  end
end
