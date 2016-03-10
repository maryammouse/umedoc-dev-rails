class ChangeColumnNamesOnOnlineLocations < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table online_locations
        rename column license_state to state;
      alter table online_locations
        rename column license_country to country;
                SQL
  end

  def down
    execute  <<-SQL
      alter table online_locations
        rename column state to license_state;
      alter table online_locations
        rename column country to license_country ;
                SQL
  end
end
