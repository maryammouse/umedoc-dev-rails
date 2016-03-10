class RemoveEmailsTable < ActiveRecord::Migration
  def up
    execute " DROP TABLE emails"
  end
  def down
    execute " CREATE TABLE emails(
              email_address varchar(255) PRIMARY KEY,
              username varchar(64) NOT NULL REFERENCES users(username)
    )"
  end
end
