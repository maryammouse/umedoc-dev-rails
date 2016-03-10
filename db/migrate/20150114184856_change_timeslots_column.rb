class ChangeTimeslotsColumn < ActiveRecord::Migration
  def change
    change_table :timeslots do |t|
      t.remove :times
      t.tstzrange :timerange
    end
  end
end
