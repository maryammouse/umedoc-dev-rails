class AddNotNullConstraintsToPhones < ActiveRecord::Migration
  def up
    execute " ALTER TABLE phones
              ALTER COLUMN number SET NOT NULL,
              ALTER COLUMN phone_type SET NOT NULL
    "
  end

  def down
    execute " ALTER TABLE phones
              ALTER COLUMN number DROP NOT NULL,
              ALTER COLUMN phone_type DROP NOT NULL
    "
  end
end
