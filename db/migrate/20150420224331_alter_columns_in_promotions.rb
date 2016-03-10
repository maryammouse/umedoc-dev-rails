class AlterColumnsInPromotions < ActiveRecord::Migration
  def up
    execute " ALTER TABLE promotions
              ALTER COLUMN start_time SET DEFAULT '00:00:00 PST',
              ALTER COLUMN end_time SET DEFAULT '24:00:00 PST'
    "
  end

  def down
    execute " ALTER TABLE promotions
              ALTER COLUMN start_time DROP DEFAULT,
              ALTER COLUMN end_time DROP DEFAULT
    "
  end
end
