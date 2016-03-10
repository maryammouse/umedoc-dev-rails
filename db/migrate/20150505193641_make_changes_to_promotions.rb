class MakeChangesToPromotions < ActiveRecord::Migration
  def change
    execute " ALTER TABLE promotions
              DROP COLUMN start_date,
              DROP COLUMN end_date,
              DROP COLUMN start_time,
              DROP COLUMN end_time,
              ADD COLUMN timerange tstzrange NOT NULL
    "
  end
end
