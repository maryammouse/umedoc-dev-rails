class CreateStripeSellers < ActiveRecord::Migration
  def up
    execute " CREATE TABLE stripe_sellers(
              id serial primary key,
              user_id integer not null REFERENCES users(id),
              token varchar(255) not null
    )"
  end

  def down
    execute " DROP TABLE stripe_sellers"
  end
end
