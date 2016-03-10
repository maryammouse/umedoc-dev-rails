# == Schema Information
#
# Table name: medical_licenses
#
#  id                     :integer          not null, primary key
#  license_number         :string(255)      not null
#  first_issued_date      :date             not null
#  expiry_date            :date             not null
#  created_at             :datetime
#  updated_at             :datetime
#  doctor_id              :integer          not null
#  state_medical_board_id :integer          not null
#

FactoryGirl.define do
  factory :medical_license do
    before(:build) do |n|
      if n.doctor_id.nil?
        n.doctor_id = FactoryGirl.create(:doctor).id
      end
    end

    before(:create) do |n|
      if n.doctor_id.nil?
        n.doctor_id = FactoryGirl.create(:doctor).id
      end
    end

    state_medical_board_id { StateMedicalBoard.all.sample.id }
    license_number { Faker::Number.number(10) }
    first_issued_date { Faker::Date.backward(18000) }
    expiry_date { Faker::Date.forward(730) }
  end

end
