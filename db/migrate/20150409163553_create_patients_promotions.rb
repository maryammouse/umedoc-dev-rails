class CreatePatientsPromotions < ActiveRecord::Migration
  def up
    execute " CREATE TABLE patients_promotions(
              id serial primary key,
              patient_id integer not null,
              promotion_id integer not null
    )"
  end

  def down
    execute " DROP TABLE IF EXISTS patients_promotions"
  end
end
