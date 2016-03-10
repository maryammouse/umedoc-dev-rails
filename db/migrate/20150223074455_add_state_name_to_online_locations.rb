class AddStateNameToOnlineLocations < ActiveRecord::Migration
  def up
    execute  <<-SQL
      delete from oncall_times_online_locations;
      delete from online_locations;
      alter table online_locations
        add column state_name text unique not null;
                SQL
  end

  def down
    execute  <<-SQL
      alter table online_locations
        drop column state_name;

                SQL
  end
end
