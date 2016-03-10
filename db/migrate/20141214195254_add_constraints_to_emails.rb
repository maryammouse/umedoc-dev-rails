class AddConstraintsToEmails < ActiveRecord::Migration
  def up
    execute " ALTER TABLE emails
              ALTER COLUMN email_address SET NOT NULL
            "
  end

  def down
    execute " ALTER TABLE emails
              ALTER COLUMN email_address DROP NOT NULL
            "
  end
end
