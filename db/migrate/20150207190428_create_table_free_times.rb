class CreateTableFreeTimes < ActiveRecord::Migration
  def up
    execute <<-SQL
      create table free_times (
          id serial primary key,
          timerange tstzrange not null,
          oncall_time_id integer not null references oncall_times(id),
          constraint free_times_oncall_time_id_timerange_exclusion exclude using gist(oncall_time_id with =, timerange with &&)
      )
               SQL
  end
  def down
    execute <<-SQL
      drop table free_times
               SQL
  end
end
