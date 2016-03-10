class ChangePlanIdColumnInPlans < ActiveRecord::Migration
  def up
    execute " ALTER TABLE plans
              ALTER COLUMN plan_id TYPE text"
  end

  def down
    execute "ALTER TABLE plans
              ALTER COLUMN plan_id TYPE integer
    "
  end
end
