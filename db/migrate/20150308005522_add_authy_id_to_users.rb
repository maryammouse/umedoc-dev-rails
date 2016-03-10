class AddAuthyIdToUsers < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table users
        add column authy_id integer
          not null
          unique;
                SQL
  end

  def down
    execute  <<-SQL
      alter table users
        drop column if exists authy_id;

                SQL
  end
end
