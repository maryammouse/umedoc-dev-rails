class AddIdToTemporaryCredentials < ActiveRecord::Migration
  def up
    execute " ALTER TABLE temporary_credentials
              ADD COLUMN id serial PRIMARY KEY

    "
  end

  def down
    execute " ALTER TABLE temporary_credentials
              DROP COLUMN id
    "
  end
end
