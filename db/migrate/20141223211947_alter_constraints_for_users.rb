class AlterConstraintsForUsers < ActiveRecord::Migration
  def up
    execute " ALTER TABLE users
              ALTER COLUMN username TYPE varchar(255)
    "
  end

  def down
    execute " ALTER TABLE users
              ALTER COLUMN username TYPE varchar(15)
    "
  end
end
