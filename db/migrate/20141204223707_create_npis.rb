class CreateNpis < ActiveRecord::Migration
  def change
    create_table :npis do |t|
      t.string :npi_number
      t.string :valid_in
      t.date :issued_date

      t.timestamps
    end
  end
end
