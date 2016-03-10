class ChangeAcceptanceToTextOnVisits < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table visits
        drop column if exists jurisdiction_acceptance,
        add column jurisdiction text
          not null
          default 'not_accepted'
          check (jurisdiction = any(array['accepted', 'not_accepted']));

                SQL
  end

  def down
    execute  <<-SQL
      alter table visits
        drop column if exists jurisdiction,
        add column jurisdiction_acceptance boolean
          not null
          default false;

                SQL
  end
end
