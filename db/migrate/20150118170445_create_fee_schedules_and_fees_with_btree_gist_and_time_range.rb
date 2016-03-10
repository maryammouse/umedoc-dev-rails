class CreateFeeSchedulesAndFeesWithBtreeGistAndTimeRange < ActiveRecord::Migration
  def up
    execute "
      CREATE EXTENSION btree_gist;

      create type timerange as range (subtype = time);


      create table fee_schedules (
        doctor_id integer references doctors (id),
        id serial primary key,
        name text constraint name_check check (length(name) < 32)
      );

      create table fees (
        id serial primary key,
        day_of_week integer constraint day_of_week_check check (day_of_week in (0,1,2,3,4,5,6)),
        time_range timerange,
        fee numeric(4, 0),
        fee_schedule_id integer references fee_schedules (id),
        exclude using gist (fee_schedule_id with =,
                            day_of_week with =,
                            time_range with &&)
      );
    "
  end

  def down
    execute "
      drop EXTENSION btree_gist;
      drop type timerange;
      drop table fee_schedules;
      drop table fees"
  end
end

# time values automatically constrained to 00:00 - 24:00
