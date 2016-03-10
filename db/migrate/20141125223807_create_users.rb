class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :firstname
      t.string :lastname
      t.date :dob
      t.string :email
      t.integer :ssn
      t.integer :cellnumber

      t.timestamps
    end
  end
end
