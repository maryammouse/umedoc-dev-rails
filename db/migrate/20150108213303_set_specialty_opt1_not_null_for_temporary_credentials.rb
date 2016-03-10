class SetSpecialtyOpt1NotNullForTemporaryCredentials < ActiveRecord::Migration
  def up
    execute " ALTER TABLE temporary_credentials
              ALTER COLUMN specialty_opt1 DROP NOT NULL
    "
  end

  def down
    execute " ALTER TABLE temporary_credentials
              ALTER COLUMN specialty_opt1 SET NOT NULL
    "
  end
end
