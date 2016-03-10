class CreateStates < ActiveRecord::Migration
  def up
    execute "
      create table states(
        name        varchar(255) not null,
        country_iso varchar(3) references countries(iso),
        iso         varchar(16),
        primary key(country_iso, iso)
        )
    "
  end
  def drop
    execute "
      drop table states
    "
  end
end
