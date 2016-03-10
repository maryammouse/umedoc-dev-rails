# == Schema Information
#
# Table name: oncall_times_online_locations
#
#  id                 :integer          not null, primary key
#  oncall_time_id     :integer          not null
#  online_location_id :integer          not null
#

FactoryGirl.define do
  factory :oncall_times_online_location do
    online_location_id { OnlineLocation.all.sample.id }
    oncall_time_id { FactoryGirl.create(:oncall_time).id }
  end

end
