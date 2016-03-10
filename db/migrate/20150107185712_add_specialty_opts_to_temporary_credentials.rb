class AddSpecialtyOptsToTemporaryCredentials < ActiveRecord::Migration
  def up
    execute " ALTER TABLE temporary_credentials
              ADD COLUMN specialty_opt1 varchar(255) references specialties(name),
              ADD COLUMN specialty_opt2 varchar(255) references specialties(name)
      "
  end

  def down
    execute " ALTER TABLE temporary_credentials
              DROP COLUMN specialty_opt1,
              DROP COLUMN specialty_opt2
    "
  end
end
