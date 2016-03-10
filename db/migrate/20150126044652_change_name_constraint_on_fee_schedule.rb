class ChangeNameConstraintOnFeeSchedule < ActiveRecord::Migration
  def up
    execute "
      alter table fee_schedules
        drop constraint name_unique,
        add constraint name_unique unique (doctor_id, name)
    "
  end

  def down
    execute "
      alter table fee_schedules
        drop constraint name_unique,
        add constraint name_unique unique (name)
    "
  end

end
