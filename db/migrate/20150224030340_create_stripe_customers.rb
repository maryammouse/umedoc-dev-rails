class CreateStripeCustomers < ActiveRecord::Migration
  def up
    execute " CREATE TABLE stripe_customers(
              id serial primary key,
              customer_id varchar(255) not null,
              user_id integer not null REFERENCES users(id)
    )
    "
  end
  def down
    execute " DROP TABLE stripe_customers"
  end
end
