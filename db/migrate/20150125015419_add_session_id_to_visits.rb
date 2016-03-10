class AddSessionIdToVisits < ActiveRecord::Migration
  def up
    execute " ALTER TABLE visits
              ADD COLUMN session_id varchar(255) not null unique
    "
  end
  def down
    execute " ALTER TABLE visits
              DROP COLUMN session_id
    "
  end
end
