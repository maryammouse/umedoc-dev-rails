class AddConfirmedEmailToUser < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table users
        drop column if exists email_confirmation,
        drop column if exists email_confirmation_token,
        add column email_confirmation text
          not null
          default 'not_confirmed'
          check (email_confirmation = any(array['confirmed', 'not_confirmed'])),
        add column email_confirmation_token varchar;

                SQL
  end

  def down
    execute  <<-SQL
      alter table users
        drop column if exists email_confirmation,
        drop column if exists email_confirmation_token;

                SQL
  end
end
