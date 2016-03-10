class CreateVisitsTable < ActiveRecord::Migration
  def up
    execute " CREATE TABLE visits(
              id serial primary key,
              patient_id integer references users(id) not null,
              doctor_id integer references doctors(id) not null,
              start_time timestamp not null,
              end_time timestamp not null,
              jurisdiction_acceptance boolean not null default false,
              paid boolean not null default false
    )"
  end

  def down
    execute " DROP TABLE visits"
  end
end
