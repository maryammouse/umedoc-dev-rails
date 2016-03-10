class AddUniqueIndexForCampaignAndEmailMailingList < ActiveRecord::Migration
  def up
    execute " ALTER TABLE mailing_lists
    DROP CONSTRAINT IF EXISTS mailing_lists_email_key;
    CREATE UNIQUE INDEX email_campaign ON mailing_lists (email, campaign)"
  end

  def down
    execute "DROP INDEX IF EXISTS email_campaign"
  end
end
