class AddBookableToOncallTimes < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table oncall_times
        add column bookable boolean not null default false;

                SQL
  end

  def down
    execute  <<-SQL
      alter table oncall_times
        drop column bookable;
                SQL
  end
end
