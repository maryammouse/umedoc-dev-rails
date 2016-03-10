class CreateDeas < ActiveRecord::Migration
  def change
    create_table :deas do |t|
      t.string :dea_number
      t.string :valid_in
      t.date :issued_date
      t.date :expiry_date

      t.timestamps
    end
  end
end
