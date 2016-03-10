# == Schema Information
#
# Table name: temporary_credentials
#
#  specialty_opt1         :string(255)      not null
#  specialty_opt2         :string(255)      not null
#  license_number         :string(20)       not null
#  doctor_id              :integer          not null
#  is_general_practice    :text             default("0"), not null
#  state_medical_board_id :integer
#  id                     :integer          not null, primary key
#

FactoryGirl.define do
  factory :temporary_credential do
    doctor_id { FactoryGirl.create(:doctor).id }
    license_number { Faker::Number.number(10) }
    state_medical_board_id { StateMedicalBoard.all.sample.id }
    is_general_practice '1'
    specialty_opt1 { Forgery::Specialty.specialty }
    specialty_opt2 { Forgery::Specialty.specialty }
  end
end
