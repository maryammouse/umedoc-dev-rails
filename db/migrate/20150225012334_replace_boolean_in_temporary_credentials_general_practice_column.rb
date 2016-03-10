class ReplaceBooleanInTemporaryCredentialsGeneralPracticeColumn < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table temporary_credentials
        drop column if exists general_practice,
        add column is_general_practice text
          not null
          default '0'
          check(is_general_practice = any(array['0', '1']));

                SQL
  end

  def down
    execute  <<-SQL
      alter table temporary_credentials
        drop column if exists is_general_practice,
        add column general_practice boolean
          not null
          default false;

                SQL
  end
end
