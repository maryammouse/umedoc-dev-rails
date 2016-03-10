class CreateCredentials < ActiveRecord::Migration
  def change
    create_table :credentials do |t|
      t.string :credential_type
      t.string :awarded_by
      t.string :location
      t.string :reference_number
      t.date :from_date
      t.date :expiry_data

      t.timestamps
    end
  end
end
