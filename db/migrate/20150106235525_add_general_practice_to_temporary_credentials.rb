class AddGeneralPracticeToTemporaryCredentials < ActiveRecord::Migration
  def up
    execute " ALTER TABLE temporary_credentials
              ADD COLUMN general_practice boolean not null
    "
  end

  def down
    execute " ALTER TABLE temporary_credentials
              DROP COLUMN general_practice"
  end
end
