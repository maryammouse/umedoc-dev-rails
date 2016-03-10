# == Schema Information
#
# Table name: patients_promotions
#
#  id           :integer          not null, primary key
#  patient_id   :integer          not null
#  promotion_id :integer          not null
#  uses_counter :integer          not null
#

FactoryGirl.define do
  factory :patients_promotion do
    
  end

end
