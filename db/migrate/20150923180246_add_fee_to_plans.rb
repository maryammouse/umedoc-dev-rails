class AddFeeToPlans < ActiveRecord::Migration
  def up
    execute " ALTER TABLE plans
              ADD COLUMN fee integer NOT NULL
    "
  end

  def down
    execute " ALTER TABLE plans
              DROP COLUMN fee
    "
  end
end
