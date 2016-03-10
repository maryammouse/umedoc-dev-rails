# == Schema Information
#
# Table name: npis
#
#  id          :integer          not null, primary key
#  npi_number  :string(255)      not null
#  valid_in    :string(255)      not null
#  issued_date :date             not null
#  created_at  :datetime
#  updated_at  :datetime
#  doctor_id   :integer          not null
#

FactoryGirl.define do
  factory :npi do
    npi_number { Forgery::ReferenceNumber.npi_number }
    valid_in { 'US' }
    issued_date { Faker::Time.between(35.years.ago, Time.now) }
    doctor_id { FactoryGirl.create(:doctor).id }
  end
end
