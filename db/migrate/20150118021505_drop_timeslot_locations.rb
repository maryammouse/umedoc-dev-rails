class DropTimeslotLocations < ActiveRecord::Migration
  def change
    drop_table :timeslot_locations
  end
end
