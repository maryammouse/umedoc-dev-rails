class AddNotNullToDoctorIdOnFeeSchedules < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table fee_schedules
        alter column doctor_id set not null;

                SQL
  end

  def down
    execute  <<-SQL
      alter table fee_schedules
        alter column doctor_id drop not null;

                SQL
  end
end
