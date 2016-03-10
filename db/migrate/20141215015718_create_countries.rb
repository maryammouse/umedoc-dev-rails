class CreateCountries < ActiveRecord::Migration
  def change
    execute "
      create table countries(
        name varchar(255),
        iso  varchar(2) primary key
        )
    "
  end
end
