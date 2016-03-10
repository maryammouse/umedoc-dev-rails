class AddColumnsToSubscriptions < ActiveRecord::Migration
  def up
    execute "ALTER TABLE subscription
            ADD COLUMN plan_id integer REFERENCES plans(id),
            ADD COLUMN status text NOT NULL CHECK (status IN ('active', 'past_due',
            'canceled', 'unpaid'))
    "
  end

  def down
    execute " ALTER TABLE subscription
              DROP COLUMN plan_id,
              DROP COLUMN status
              "
  end
end
