class AddLinkedInToDoctors < ActiveRecord::Migration
  def up
    execute "alter table doctors
    add column linked_in varchar(255)
    "
  end

  def down
    execute "alter table doctors
    drop column linked_in
    "
  end
end
