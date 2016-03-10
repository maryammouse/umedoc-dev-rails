class AlterFeeSchedulesNameDefault < ActiveRecord::Migration
  def up
    execute "
      alter table fee_schedules
        alter column name set default 'Default',
        alter column name set not null,
        add constraint name_unique unique (name)
    "
  end
  def down
    execute "
      alter table fee_schedules
        alter column name drop default,
        alter column name drop not null,
        drop constraint name_unique
      "
  end
end
