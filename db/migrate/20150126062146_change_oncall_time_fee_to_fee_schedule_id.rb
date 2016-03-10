class ChangeOncallTimeFeeToFeeScheduleId < ActiveRecord::Migration
  def up
    execute "
      alter table oncall_times
          rename column fee to fee_schedule_id;
      alter table oncall_times
          add constraint fee_schedule_fk foreign key (fee_schedule_id) references fee_schedules (id)
    "
  end
  def down
    execute "
      alter table oncall_times
          drop constraint fee_schedule_fk;
      alter table oncall_times
          rename column fee_schedule_id to fee
    "
  end
end
