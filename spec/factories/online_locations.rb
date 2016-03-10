# == Schema Information
#
# Table name: online_locations
#
#  state      :string(2)        not null
#  country    :string(2)        not null
#  id         :integer          not null, primary key
#  state_name :text             not null
#

FactoryGirl.define do
  factory :online_location do
    state 'CA'
    country 'US'
    state_name 'California'
  end

end
