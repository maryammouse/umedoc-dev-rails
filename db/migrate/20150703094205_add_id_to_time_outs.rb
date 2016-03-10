class AddIdToTimeOuts < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table time_outs
        add column id serial primary key;

                SQL
  end

  def down
    execute  <<-SQL
      alter table time_outs
        drop column id if exists;

                SQL
  end
end
