class AddPasswordDigestToUsersRemovePassword < ActiveRecord::Migration
  def up
    execute " ALTER TABLE users
              DROP COLUMN password,
              ADD COLUMN password_digest varchar(255) not null
    "
  end
  def down
    execute " ALTER TABLE users
              DROP COLUMN password_digest,
              ADD COLUMN password varchar(25) not null
    "
  end
end
