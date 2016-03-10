class RemovePaidFromVisits < ActiveRecord::Migration
  def up
    execute " ALTER TABLE visits
              DROP COLUMN paid
    "
  end
  def down
    execute " ALTER TABLE visits
              ADD COLUMN paid boolean not null
    "
  end
end
