class ChangeFreeTimesForeignKeyToCascade < ActiveRecord::Migration
  def up
    execute <<-SQL
      alter table free_times drop constraint if exists free_times_oncall_time_id_fkey;
      alter table free_times add constraint free_times_oncall_time_id_fkey
        FOREIGN KEY (oncall_time_id) references oncall_times(id) on delete cascade;
              SQL
  end
  def down
    execute <<-SQL
      alter table free_times drop constraint if exists free_times_oncall_time_id_fkey;
      alter table free_times add constraint free_time_oncall_time_id_fkey
        FOREIGN KEY (oncall_time_id) references oncall_times(id);
              SQL
  end
end
