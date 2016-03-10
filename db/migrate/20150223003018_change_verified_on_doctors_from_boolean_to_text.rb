class ChangeVerifiedOnDoctorsFromBooleanToText < ActiveRecord::Migration

  def up
    execute  <<-SQL
      alter table doctors
        drop column if exists verified,
        add column verification_status text not null default 'not_verified',
        add constraint verification_status_check check(verification_status = ANY (ARRAY['not_verified'::text, 'verified'::text]));

                SQL
  end

  def down
    execute  <<-SQL
      alter table doctors
        drop constraint if exists verification_status_check,
        drop column if exists verification_status,
        add column verified boolean not null default false;

                SQL
  end
end
