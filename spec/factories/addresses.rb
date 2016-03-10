# == Schema Information
#
# Table name: addresses
#
#  id               :integer          not null, primary key
#  address_type     :string(255)
#  street_address_1 :string(255)      not null
#  street_address_2 :string(255)
#  city             :string(255)      not null
#  state            :string(255)      not null
#  zip_code         :string(255)      not null
#  created_at       :datetime
#  updated_at       :datetime
#  mailing_name     :string(255)      not null
#  latitude         :float
#  longitude        :float
#  user_id          :integer          not null
#

FactoryGirl.define do
  factory :address do
    mailing_name { Faker::Name.name }
    address_type "business"
    street_address_1 "3261 Sunset Avenue"
    street_address_2 "Apt 101"
    city "Menlo Park"
    state "CA"
    zip_code "94025"
    user_id { FactoryGirl.create(:user).id }
  end
end
