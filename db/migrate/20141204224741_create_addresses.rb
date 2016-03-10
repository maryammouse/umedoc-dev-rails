class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.string :mailing_name
      t.string :address_type
      t.string :street_address_1
      t.string :street_address_2
      t.string :city
      t.string :state
      t.string :zip_code

      t.timestamps
    end
  end
end
