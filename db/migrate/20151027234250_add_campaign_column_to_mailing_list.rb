class AddCampaignColumnToMailingList < ActiveRecord::Migration
  def up
    execute " ALTER TABLE mailing_lists
              ADD COLUMN campaign text NOT NULL DEFAULT 'Umedoc You'
    "
  end

  def down
    execute " ALTER TABLE mailing_lists
              DROP COLUMN campaign
    "
  end
end
