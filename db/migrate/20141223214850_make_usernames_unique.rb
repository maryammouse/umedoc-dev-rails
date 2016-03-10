class MakeUsernamesUnique < ActiveRecord::Migration
  def up
    execute " ALTER TABLE users
              ADD CONSTRAINT username_unique UNIQUE (username)
    "
  end
  def down
    execute " ALTER TABLE users
              DROP CONSTRAINT username_unique
    "
  end
end
