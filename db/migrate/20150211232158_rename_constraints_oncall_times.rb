class RenameConstraintsOncallTimes < ActiveRecord::Migration
  def up
    execute  <<-SQL
      -- alter table oncall_times rename constraint timeslots_pkey to oncall_times_pkey;
      alter table oncall_times rename constraint timeslots_doctor_id_fkey to oncall_times_doctor_id_fkey;
      alter table oncall_times alter column timerange set not null;
      drop table if exists timeslots;
                SQL
  end

  def down
      raise ActiveRecord::IrreversibleMigration
  end
end
