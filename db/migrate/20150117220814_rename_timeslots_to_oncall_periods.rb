class RenameTimeslotsToOncallPeriods < ActiveRecord::Migration
  def change
    rename_table :timeslots, :oncall_times
  end 
end
