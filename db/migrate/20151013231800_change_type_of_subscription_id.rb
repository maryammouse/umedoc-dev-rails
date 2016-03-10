class ChangeTypeOfSubscriptionId < ActiveRecord::Migration
  def up
    execute " ALTER TABLE subscriptions
              ALTER COLUMN subscription_id TYPE text
    "
  end

  def down
    raise IrreversibleMigration
  end

end
