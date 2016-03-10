class CreatePlans < ActiveRecord::Migration
  def up
    execute " CREATE TABLE plans(
              id serial PRIMARY KEY,
              plan_id integer NOT NULL UNIQUE,
              stripe_seller_id integer NOT NULL UNIQUE REFERENCES stripe_sellers(id)
    )"
  end

  def down
    execute "DROP TABLE plans"
  end
end
