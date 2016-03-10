class AddDurationToMultipleTables < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table oncall_times
        add column duration timestamptz not null;
      alter table visits
        add column duration timestamptz not null;
      alter table free_times
        add column duration timestamptz not null;

                SQL
  end

  def down
    execute  <<-SQL
      alter table oncall_times
        drop column duration;
      alter table visits
        drop column duration;
      alter table free_times
        drop column duration;

                SQL
  end
end
