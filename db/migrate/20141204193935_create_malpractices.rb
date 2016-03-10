class CreateMalpractices < ActiveRecord::Migration
  def change
    create_table :malpractices do |t|
      t.string :policy_number
      t.string :valid_location
      t.string :speciality
      t.boolean :in_person
      t.boolean :telemedicine
      t.string :policy_type
      t.integer :coverage_amount

      t.timestamps
    end
  end
end
