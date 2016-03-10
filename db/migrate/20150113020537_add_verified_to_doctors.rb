class AddVerifiedToDoctors < ActiveRecord::Migration
  def up
    execute " ALTER TABLE doctors
              ADD COLUMN verified boolean not null default false
    "
  end

  def down
    execute " ALTER TABLE doctors
              DROP COLUMN verified
    "
  end
end
