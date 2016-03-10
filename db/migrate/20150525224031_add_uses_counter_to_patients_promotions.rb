class AddUsesCounterToPatientsPromotions < ActiveRecord::Migration
  def up
    execute " ALTER TABLE patients_promotions
              ADD COLUMN uses_counter integer NOT NULL
    "
  end
  def down
    execute " ALTER TABLE patients_promotions
              DROP COLUMN uses_counter
    "
  end
end
