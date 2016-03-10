# == Schema Information
#
# Table name: visits_office_locations
#
#  visit_id           :integer          not null
#  office_location_id :integer          not null
#  id                 :integer          not null, primary key
#

FactoryGirl.define do
  factory :visits_office_location do
    visit_id { FactoryGirl.create(:visit).id }
    office_location_id { FactoryGirl.create(:office_location).id }
    
  end

end
