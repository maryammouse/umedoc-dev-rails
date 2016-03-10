class CreateOncallTimeLocationOnline < ActiveRecord::Migration
  def up
    execute "
	create table oncall_times_online_locations  (
		oncall_times_id integer  references oncall_times (id),
		online_locations_id integer references online_locations (id)

	)

      "
    
  end
  def down
    execute "drop table oncall_times_online_locations"
  end
end
