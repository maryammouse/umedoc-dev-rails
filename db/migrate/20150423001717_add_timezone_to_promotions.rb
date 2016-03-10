class AddTimezoneToPromotions < ActiveRecord::Migration
  def up
    execute " ALTER TABLE promotions
              ADD COLUMN timezone text NOT NULL
    "
  end

  def down
    execute " ALTER TABLE promotions
              DROP COLUMN IF EXISTS timezone
    "
  end
end
