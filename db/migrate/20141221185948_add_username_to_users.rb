class AddUsernameToUsers < ActiveRecord::Migration
  def up
    execute " ALTER TABLE users
              DROP CONSTRAINT users_pkey,
              ADD username varchar(15) PRIMARY KEY,
              ADD password varchar(25) NOT NULL"
  end

  def down
    execute " ALTER TABLE users
              DROP COLUMN username,
              DROP COLUMN password,
              ADD PRIMARY KEY (id)"
  end
end

