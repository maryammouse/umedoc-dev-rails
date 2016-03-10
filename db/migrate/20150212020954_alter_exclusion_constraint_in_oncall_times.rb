class AlterExclusionConstraintInOncallTimes < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table oncall_times
        drop constraint if exists doctor_id_timerange_excl;
      alter table oncall_times
        add constraint doctor_id_timerange_bookable_excl
          exclude using gist (doctor_id WITH =, timerange WITH &&)
          where (bookable = TRUE)
                SQL
  end

  def down
    execute  <<-SQL

      alter table oncall_times
        drop constraint if exists doctor_id_timerange_bookable_excl;

      alter table oncall_times
        add constraint doctor_id_timerange_excl
          exclude using gist (doctor_id with =, timerange with &&);
                SQL
  end
end
