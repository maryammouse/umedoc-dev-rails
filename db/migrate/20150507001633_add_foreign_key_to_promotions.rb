class AddForeignKeyToPromotions < ActiveRecord::Migration
  def up
    execute " ALTER TABLE promotions
              ADD COLUMN doctor_id integer not null REFERENCES doctors(id)
    "
  end
  def down
    execute " ALTER TABLE promotions
              DROP COLUMN doctor_id
    "
  end
end
