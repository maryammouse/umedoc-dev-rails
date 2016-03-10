class AddIdToMailingList < ActiveRecord::Migration
  def up
    execute "ALTER TABLE mailing_lists
            DROP CONSTRAINT IF EXISTS mailing_lists_pkey ,
            ADD COLUMN id serial PRIMARY KEY "
  end

  def down
    execute "ALTER TABLE mailing_lists
            DROP CONSTRAINT mailing_lists_pkey,
            DROP COLUMN id,
            ADD PRIMARY KEY (email)"
  end
end
