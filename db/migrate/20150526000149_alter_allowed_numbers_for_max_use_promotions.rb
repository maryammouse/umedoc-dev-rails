class AlterAllowedNumbersForMaxUsePromotions < ActiveRecord::Migration
  def change
    execute " ALTER TABLE promotions
              DROP CONSTRAINT promotions_max_uses_per_patient_check
    "
  end
end
