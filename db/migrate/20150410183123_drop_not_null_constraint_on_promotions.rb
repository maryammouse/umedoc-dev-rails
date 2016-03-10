class DropNotNullConstraintOnPromotions < ActiveRecord::Migration
  def up
    execute " ALTER TABLE promotions
              ALTER COLUMN name DROP NOT NULL
    "
  end

  def down
    execute " ALTER TABLE promotions
              ALTER COLUMN name SET NOT NULL
    "
  end
end
