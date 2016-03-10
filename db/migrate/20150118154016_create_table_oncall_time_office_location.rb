class CreateTableOncallTimeOfficeLocation < ActiveRecord::Migration
  def up
    execute "
      create table oncall_times_office_locations (
        oncall_times_id integer references oncall_times (id),
        office_locations_id integer references office_locations (id)
      )
    "
  end
  def down
    execute "drop table oncall_times_office_locations"
  end
end
