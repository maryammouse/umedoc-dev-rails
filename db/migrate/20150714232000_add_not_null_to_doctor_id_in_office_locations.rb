class AddNotNullToDoctorIdInOfficeLocations < ActiveRecord::Migration
  def up
    #execute "ALTER TABLE office_locations
             #ALTER COLUMN doctor_id SET NOT NULL"
    puts "empty migration so that things don't break"
  end

  def down
    #execute "ALTER TABLE office_locations
            #ALTER COLUMN doctor_id DROP NOT NULL"
    puts "empty migration so that things don't break"
  end
end
