class CreateDoctors < ActiveRecord::Migration
  def up
    execute "
      create table doctors (
        id serial primary key,
        user_id integer references users(id) unique not null
      );
    "
  end

  def down
    execute "
      drop table doctors;
    "
  end
end
