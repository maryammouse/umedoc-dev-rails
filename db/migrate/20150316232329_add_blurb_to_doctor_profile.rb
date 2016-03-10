class AddBlurbToDoctorProfile < ActiveRecord::Migration
  def up
    execute "alter table doctors
            add column blurb text
    "
  end

  def down
    execute "alter table doctors
            drop column blurb
    "
  end
end
