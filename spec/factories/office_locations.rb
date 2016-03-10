# == Schema Information
#
# Table name: office_locations
#
#  street_address_1 :string(64)       not null
#  street_address_2 :string(64)
#  city             :string(32)       not null
#  state            :string(2)        not null
#  zip_code         :string(5)        not null
#  id               :integer          not null, primary key
#  country          :text             not null
#  doctor_id        :integer

FactoryGirl.define do
  factory :office_location do

    street_address_1 { '3261 Faraday Hall' }
    city { PrimaryCity.all.sample.name }
    state { State.where(country_id: 'US').all.sample.iso }
    zip_code { ZipCode.all.sample.zip }
    country { 'US' }
    doctor_id { FactoryGirl.create(:doctor).id }
  end

end
