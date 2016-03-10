class AddDiscountColumnsToPromotions < ActiveRecord::Migration
  def up
    execute " ALTER TABLE promotions
              ADD COLUMN discount_type text NOT NULL CHECK (discount_type in ('percentage', 'fixed'))
    "
  end

  def down
    execute " ALTER TABLE promotions
              DROP COLUMN IF EXISTS discount_type
    "
  end
end
