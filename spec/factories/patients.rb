# == Schema Information
#
# Table name: patients
#
#  id      :integer          not null, primary key
#  user_id :integer          not null
#

FactoryGirl.define do
  factory :patient do


    association :user
    #user_id { FactoryGirl.create(:user).id }
  end

end
