class AddIssueDateToBoardCertification < ActiveRecord::Migration
  def change
    add_column :board_certifications, :issue_date, :date
  end
end
