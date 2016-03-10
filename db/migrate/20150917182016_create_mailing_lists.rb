class CreateMailingLists < ActiveRecord::Migration
  def up
    execute "CREATE TABLE mailing_lists (
    email text unique not null
    )"
  end

  def down
    execute "DROP TABLE mailing_lists"
  end
end
