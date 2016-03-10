class CreatePromotions < ActiveRecord::Migration
  def up
    execute " CREATE TABLE PROMOTIONS(
              start_date date not null,
              end_date date not null,
              start_time timetz not null,
              end_time timetz not null,
              discount integer not null,
              max_uses_per_patient integer not null
              CHECK ((max_uses_per_patient <= 10 AND max_uses_per_patient > 0) 
              OR max_uses_per_patient = 999999 ),
              active text not null CHECK (active in ('active', 'not_active')),
              name varchar(255) not null,
              promo_code varchar(255) not null unique,
              id serial primary key

    )"
  end

  def down
    execute " DROP TABLE IF EXISTS promotions"
  end
end
