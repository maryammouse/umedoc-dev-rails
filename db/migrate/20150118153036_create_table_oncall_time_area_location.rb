class CreateTableOncallTimeAreaLocation < ActiveRecord::Migration
  def up
    execute "
      create table oncall_times_area_locations (
        oncall_times_id integer references oncall_times (id),
        area_locations_id integer references area_locations (id)
      )
      
    "
  end
  def down
    execute "drop table oncall_times_area_locations"
  end
end
