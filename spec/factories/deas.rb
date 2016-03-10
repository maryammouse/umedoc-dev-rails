# == Schema Information
#
# Table name: deas
#
#  dea_number  :string(255)      not null, primary key
#  valid_in    :string(255)      not null
#  issued_date :date             not null
#  expiry_date :date             not null
#  created_at  :datetime
#  updated_at  :datetime
#  doctor_id   :integer          not null
#

FactoryGirl.define do
  factory :dea do
    dea_number { Forgery::ReferenceNumber.dea_number }
    valid_in { Forgery::Address.state_abbrev }
    issued_date { Faker::Time.between(3.years.ago, Time.now) }
    expiry_date { Faker::Time.forward(1095) + 1.month }
  end
end
