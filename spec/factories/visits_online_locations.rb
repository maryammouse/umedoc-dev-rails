# == Schema Information
#
# Table name: visits_online_locations
#
#  visit_id           :integer          not null
#  online_location_id :integer          not null
#  id                 :integer          not null, primary key
#

FactoryGirl.define do
  factory :visits_online_location do
    visit_id { FactoryGirl.create(:visit).id }
    online_location_id { OnlineLocation.all.sample.id }
    
  end

end
