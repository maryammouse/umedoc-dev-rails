class FixSpellingOnFeeTable < ActiveRecord::Migration

  def up
    execute  <<-SQL
      alter table fees
        rename to fee_rules;
      alter table fee_rules
        drop constraint if exists fees_fee_schedule_id_day_of_week_time_range_excl,
        drop column if exists timerange,
        drop column if exists time_range,
        drop constraint if exists fees_fee_schedule_id_fkey,
        drop column if exists fee_schedule_id,
        add column time_of_day_range timerange not null,
        add column fee_schedule_id integer not null references fee_schedules(id),
        add constraint fee_rules_fee_schedule_id_day_of_week_time_of_day_range_excl
          EXCLUDE USING gist (fee_schedule_id WITH =,
                              day_of_week WITH =,
                              time_of_day_range WITH &&);
      alter table fee_rules
        rename constraint fees_pkey to fee_rules_pkey;


                SQL
  end

  def down
    execute  <<-SQL
      alter table fee_rules
        rename constraint fee_rules_pkey to fees_pkey;

      alter table fee_rules
        rename to fees;

      alter table fees
        drop column if exists fee_schedule_id,
        add column fee_schedule_id integer references fee_schedules(id);

      alter table fees
        drop constraint if exists fee_rules_fee_schedule_id_day_of_week_time_of_day_range_excl,
        drop column if exists time_of_day_range,
        add column timerange timerange not null,
        add constraint fees_fee_schedule_id_day_of_week_time_range_excl
          EXCLUDE USING gist (fee_schedule_id WITH =,
                              day_of_week WITH =,
                              timerange WITH &&);
                SQL
  end
end
