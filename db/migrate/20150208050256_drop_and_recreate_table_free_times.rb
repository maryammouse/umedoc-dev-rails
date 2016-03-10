require_relative '20150207190428_create_table_free_times.rb'


class DropAndRecreateTableFreeTimes < ActiveRecord::Migration
  def up
    revert CreateTableFreeTimes
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
      create table free_times (
          id serial primary key,
          timerange tstzrange not null,
          oncall_time_id integer references oncall_times(id),
          constraint free_times_oncall_time_id_timerange_exclusion exclude using gist(oncall_time_id with =, timerange with &&)
      )
               SQL
  end
end
