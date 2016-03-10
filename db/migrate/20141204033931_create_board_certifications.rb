class CreateBoardCertifications < ActiveRecord::Migration
  def change
    create_table :board_certifications do |t|
      t.string :speciality
      t.string :board_name
      t.date :date_awarded

      t.timestamps
    end
  end
end
