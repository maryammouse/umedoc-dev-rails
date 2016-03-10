class CreateTableFeeRuleTimes < ActiveRecord::Migration
  def up
    execute  <<-SQL
      create table if not exists fee_rule_times (
        id serial primary key,
        fee_schedule_id integer not null references fee_schedules(id),
        timerange tstzrange not null,
        fee numeric(4,0) not null,
        visit_duration interval default '00:30:00'::interval
      );
      alter table fee_rule_times
        drop constraint if exists fee_rule_times_fee_schedule_id_excl,
        drop constraint if exists visit_duration_rounding_check;
      alter table fee_rule_times
        add constraint fee_rule_times_fee_schedule_id_excl exclude
          using gist (fee_schedule_id with =,
                      timerange with &&),
        add constraint visit_duration_rounding_check check (date_part('minute'::text, visit_duration)
                                                      = Any (Array[0,5,10,15,20,25,30,35,40,45,50,55]));

                SQL
  end

  def down
    execute  <<-SQL
      drop table if exists fee_rule_times;
                SQL
  end
end
