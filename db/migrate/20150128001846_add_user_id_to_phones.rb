class AddUserIdToPhones < ActiveRecord::Migration
  def up
    execute " ALTER TABLE phones
              ADD COLUMN user_id integer NOT NULL REFERENCES users(id)
    "
  end

  def down
    execute "ALTER TABLE phones
             DROP COLUMN user_id
    "
  end
end
