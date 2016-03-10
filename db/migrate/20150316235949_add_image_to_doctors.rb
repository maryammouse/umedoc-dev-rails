class AddImageToDoctors < ActiveRecord::Migration
  def up
    execute "alter table doctors
    add column image text
    "
  end

  def down
    execute "alter table doctors
    drop column image
    "
  end
end
