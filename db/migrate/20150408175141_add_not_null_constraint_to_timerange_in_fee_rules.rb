class AddNotNullConstraintToTimerangeInFeeRules < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table fee_rules
        alter column time_of_day_range set not null;

                SQL
  end

  def down
    execute  <<-SQL
      alter table fee_rules
        alter column time_of_day_range drop not null;

                SQL
  end
end
