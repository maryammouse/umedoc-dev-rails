class AddFeePaidToVisits < ActiveRecord::Migration
  def up
    execute  <<-SQL
      alter table visits
        add column fee_paid integer not null constraint fee_paid_positive_check check(fee_paid >=0)
                SQL
  end

  def down
    execute  <<-SQL
      alter table visits
        drop column if exists fee_paid
                SQL
  end
end
