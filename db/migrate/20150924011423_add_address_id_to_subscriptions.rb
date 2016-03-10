class AddAddressIdToSubscriptions < ActiveRecord::Migration
  def up
    execute " ALTER TABLE subscription
              ADD COLUMN address_id integer REFERENCES addresses(id)
    "
  end

  def down
    execute " ALTER TABLE subscription
              DROP COLUMN address_id
    "
  end
end
