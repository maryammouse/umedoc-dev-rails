class DropDefaultOnMailingList < ActiveRecord::Migration
  def up
    execute " ALTER TABLE mailing_lists
              ALTER COLUMN campaign DROP DEFAULT
    "
  end

  def down
    execute " ALTER TABLE mailing_lists 
              ALTER COLUMN campaign SET DEFAULT 'Umedoc You'
    "
  end
end
