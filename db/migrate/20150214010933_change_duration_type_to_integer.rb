class ChangeDurationTypeToInteger < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table oncall_times
        drop column duration,
        add column duration integer not null;
      alter table visits
        drop column duration,
        add column duration integer not null;
      alter table free_times
        drop column duration,
        add column duration integer not null;

                SQL
  end

  def down
    execute  <<-SQL
      alter table oncall_times
        drop column duration,
        add column duration interval not null;
      alter table visits
        drop column duration,
        add column duration interval not null;
      alter table free_times
        drop column duration,
        add column duration interval not null;

                SQL
  end
end
