class AddMoreAuthyColumnsToUsers < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table users
        add column cellphone varchar(50) not null,
        add column country_code varchar(5) not null default '1';

                SQL
  end

  def down
    execute  <<-SQL
      alter table users
        drop column if exists cellphone,
        drop column if exists country_code;

                SQL
  end
end
