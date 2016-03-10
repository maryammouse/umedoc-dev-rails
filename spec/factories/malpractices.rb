# == Schema Information
#
# Table name: malpractices
#
#  id               :integer          not null, primary key
#  policy_number    :string(255)      not null
#  valid_location   :string(255)      not null
#  policy_type      :string(255)      not null
#  coverage_amount  :integer          not null
#  created_at       :datetime
#  updated_at       :datetime
#  specialty        :string(255)      not null
#  doctor_id        :integer          not null
#  service_delivery :text             not null
#

FactoryGirl.define do
  factory :malpractice do
    doctor_id { FactoryGirl.create(:doctor).id }
    policy_number { Faker::Number.number(10) }
    valid_location { Forgery::Address.state_abbrev }
    specialty { Forgery::Specialty.specialty }
    service_delivery 'online'
    policy_type { Forgery::PolicyType.policy_type }
    coverage_amount { Faker::Number.number(6) }
  end
end
