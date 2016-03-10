class AddConstraintsToUsers < ActiveRecord::Migration
  def up
    execute " ALTER TABLE users
              ADD CONSTRAINT firstname_length CHECK (char_length(firstname) <= 64),
              ADD CONSTRAINT lastname_length CHECK (char_length(lastname) <= 64),
              ADD CONSTRAINT gender_type CHECK (gender in ('male', 'female', 'other' )),
              ALTER COLUMN dob SET NOT NULL,
              ALTER COLUMN firstname SET NOT NULL,
              ALTER COLUMN lastname SET NOT NULL,
              ALTER COLUMN gender SET NOT NULL
    "
  end

  def down
    execute " ALTER TABLE users
              DROP CONSTRAINT firstname_length,
              DROP CONSTRAINT lastname_length,
              DROP CONSTRAINT gender_type,
              ALTER COLUMN dob DROP NOT NULL,
              ALTER COLUMN firstname DROP NOT NULL,
              ALTER COLUMN lastname DROP NOT NULL
    "
  end
end
