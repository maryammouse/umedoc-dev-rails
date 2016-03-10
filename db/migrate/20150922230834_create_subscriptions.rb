class CreateSubscriptions < ActiveRecord::Migration
  def up
    execute 'CREATE TABLE subscription(
            stripe_customer_id integer NOT NULL UNIQUE REFERENCES stripe_customers(id),
            id serial PRIMARY KEY,
            subscription_id integer NOT NULL UNIQUE 
    )'
  end

  def down
    execute "DROP TABLE subscription"
  end
end
