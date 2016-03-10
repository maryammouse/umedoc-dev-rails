class AddAuthenticationCheckToVisits < ActiveRecord::Migration
  def up
    execute " ALTER TABLE visits
              ADD COLUMN authenticated varchar(1) not null default '0'
    "
  end

  def down
    execute " ALTER TABLE visits
              DROP COLUMN IF EXISTS authenticated
    "
  end
end
