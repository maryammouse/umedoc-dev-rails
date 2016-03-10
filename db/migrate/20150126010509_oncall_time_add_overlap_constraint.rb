class OncallTimeAddOverlapConstraint < ActiveRecord::Migration
  def up
    execute "
      alter table oncall_times
        add constraint doctor_id_timerange_excl exclude using gist(doctor_id with =, timerange with &&)
    "
  end
  def down
    execute "
      alter table oncall_times
        drop constraint doctor_id_timerange_excl
    "
  end
end

