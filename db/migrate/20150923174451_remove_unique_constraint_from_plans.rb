class RemoveUniqueConstraintFromPlans < ActiveRecord::Migration
  def up
    execute " ALTER TABLE plans
              DROP CONSTRAINT IF EXISTS plans_plan_id_key"
  end

  def down
    raise IrreversibleMigration
  end
end
