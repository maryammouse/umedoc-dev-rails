class AddDoctorForeignKeyToOfficeLocations < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table office_locations
        add column doctor_id integer references doctors(id);

                SQL
  end

  def down
    execute  <<-SQL
      alter table office_locations
        drop column if exists doctor_id;

                SQL
  end
end
