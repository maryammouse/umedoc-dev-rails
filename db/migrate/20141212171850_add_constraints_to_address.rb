class AddConstraintsToAddress < ActiveRecord::Migration
  def up
    #change_column :addresses do |t|
      #t.change(:street_address_1, :string, limit: 64)
      #t.change(:street_address_2, :string, limit: 64)
      #t.change(:city, :string, limit: 32)
      #t.change(:state, :string, limit: 2)
      #t.change(:zip_code, :string, limit: 5)
      #t.change(:)
      execute " ALTER TABLE addresses
                ADD CONSTRAINT street_address_1_length CHECK (char_length(street_address_1) <= 64),
                ADD CONSTRAINT street_address_2_length CHECK (char_length(street_address_2) <= 64),
                ADD CONSTRAINT city_length CHECK (char_length(city) <= 32),
                ADD CONSTRAINT state_length CHECK (char_length(state) = 2),
                ADD CONSTRAINT zip_code_length CHECK (char_length(zip_code) = 5)
              "
  end

  def down
    #change_column :addresses do |t|
    execute "ALTER TABLE addresses
             DROP CONSTRAINT street_address_1_length RESTRICT,
             DROP CONSTRAINT street_address_2_length RESTRICT,
             DROP CONSTRAINT city_length RESTRICT,
             DROP CONSTRAINT state_length RESTRICT,
             DROP CONSTRAINT zip_code_length RESTRICT
             "
  end
end
