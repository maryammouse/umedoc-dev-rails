class MakeIdPrimaryKeyForUsers < ActiveRecord::Migration
  def up
    execute " ALTER TABLE users
              DROP CONSTRAINT users_pkey,
              ADD PRIMARY KEY (id)
    "
  end

  def down
    execute " ALTER TABLE users
              DROP CONSTRAINT users_pkey,
              ADD PRIMARY KEY (username)
    "
  end
end
