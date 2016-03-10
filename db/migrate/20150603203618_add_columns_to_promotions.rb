class AddColumnsToPromotions < ActiveRecord::Migration
  def up
    execute " ALTER TABLE promotions
            DROP COLUMN timerange,
            ADD COLUMN applicable_timerange tstzrange NOT NULL,
            ADD COLUMN bookable_timerange tstzrange NOT NULL,
            DROP COLUMN active,
            ADD COLUMN applicable text NOT NULL CHECK (applicable in ('applicable', 'not_applicable')),
            ADD COLUMN bookable text NOT NULL CHECK (bookable in ('bookable', 'not_bookable'))
    "
  end

  def down
    execute " ALTER TABLE promotions
              DROP COLUMN applicable,
              DROP COLUMN applicable_timerange,
              DROP COLUMN bookable,
              DROP COLUMN bookable_timerange,
              ADD COLUMN active text not null CHECK (active in ('active', 'not_active')),
              ADD COLUMN timerange tstzrange NOT NULL
    "
  end
end
