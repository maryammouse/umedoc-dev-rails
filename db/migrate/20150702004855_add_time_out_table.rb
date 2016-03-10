class AddTimeOutTable < ActiveRecord::Migration
  def up
    execute  <<-SQL
      create table time_outs (
        timerange tstzrange not null,
        exclude using gist (oncall_time_id with =, timerange with && ),
        oncall_time_id integer not null references oncall_times(id)
      )

                SQL
  end

  def down
    execute  <<-SQL
      drop table if exists time_outs;

                SQL
  end
end
