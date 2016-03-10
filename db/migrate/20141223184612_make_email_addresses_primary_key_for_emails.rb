class MakeEmailAddressesPrimaryKeyForEmails < ActiveRecord::Migration
  def up
    execute " ALTER TABLE emails
              DROP CONSTRAINT emails_pkey,
              DROP COLUMN id,
              ADD PRIMARY KEY (email_address)
    "
  end

  def down
    execute " ALTER TABLE emails
              DROP CONSTRAINT emails_pkey,
              ADD COLUMN id SERIAL,
              ADD PRIMARY KEY (id)
              "
  end
end
