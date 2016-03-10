class RemoveDoctorsPromotionsIfExists < ActiveRecord::Migration
  def change
    execute " DROP TABLE IF EXISTS doctors_promotions;"
  end
end
