class CreateStripeEvents < ActiveRecord::Migration
  def up
    execute " CREATE TABLE stripe_events(
    event_id text PRIMARY KEY
    )"
  end

  def down
    execute " DROP TABLE IF EXISTS stripe_events"
  end
end
