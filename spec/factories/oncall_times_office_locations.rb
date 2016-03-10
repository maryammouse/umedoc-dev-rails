# == Schema Information
#
# Table name: oncall_times_office_locations
#
#  office_location_id :integer          not null
#  oncall_time_id     :integer          not null
#

FactoryGirl.define do
  factory :oncall_times_office_location do
    office_location_id { FactoryGirl.create(:office_location).id }
    oncall_time_id { FactoryGirl.create(:oncall_time).id }
  end

end
