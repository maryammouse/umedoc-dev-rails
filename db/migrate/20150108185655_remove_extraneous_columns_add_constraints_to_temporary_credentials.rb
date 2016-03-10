class RemoveExtraneousColumnsAddConstraintsToTemporaryCredentials < ActiveRecord::Migration
  def up
    execute " ALTER TABLE temporary_credentials
              DROP COLUMN specialty_name,
              DROP COLUMN services,
              ALTER COLUMN specialty_opt1 SET NOT NULL
    "
  end

  def down
    execute " ALTER TABLE temporary_credentials
              ADD COLUMN specialty_name varchar(64) not null,
              ADD COLUMN services varchar(50) not null,
              ALTER COLUMN specialty_opt1 DROP NOT NULL
    "
  end
end
