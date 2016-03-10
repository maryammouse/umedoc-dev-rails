class AddUserIdToAddresses < ActiveRecord::Migration
  def up
    execute " ALTER TABLE addresses 
              ADD COLUMN user_id integer not null REFERENCES users(id)
    "
  end
  def down
    execute " ALTER TABLE addresses
              DROP COLUMN user_id
    "
  end
end
