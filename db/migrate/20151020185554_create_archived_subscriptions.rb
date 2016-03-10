class CreateArchivedSubscriptions < ActiveRecord::Migration
  def up
    execute " CREATE TABLE archived_subscriptions(
              id serial PRIMARY KEY,
              subscription_id INTEGER NOT NULL REFERENCES subscriptions(id),
              stripe_data JSONB NOT NULL,
              stripe_seller_id INTEGER NOT NULL REFERENCES stripe_sellers(id)

    )"
  end

  def down
    execute " DROP TABLE IF EXISTS archived_subscriptions"
  end
end
