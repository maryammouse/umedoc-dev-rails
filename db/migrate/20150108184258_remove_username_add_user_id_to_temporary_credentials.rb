class RemoveUsernameAddUserIdToTemporaryCredentials < ActiveRecord::Migration
  def up
    execute " ALTER TABLE temporary_credentials
              DROP CONSTRAINT temporary_credentials_username_fkey,
              DROP COLUMN username,
              ADD COLUMN user_id integer NOT NULL REFERENCES users(id)
    "
  end

  def down
    execute " ALTER TABLE temporary_credentials
              DROP CONSTRAINT temporary_credentials_user_id_fkey,
              DROP COLUMN user_id,
              ADD COLUMN username varchar(255) REFERENCES users(username)
    "
  end
end
