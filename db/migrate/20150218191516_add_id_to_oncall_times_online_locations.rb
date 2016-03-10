class AddIdToOncallTimesOnlineLocations < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table oncall_times_online_locations
        add column id serial primary key;
                SQL
  end

  def down
    execute  <<-SQL
      alter table oncall_times_online_locations
        drop column id;

                SQL
  end
end
