# == Schema Information
#
# Table name: board_certifications
#
#  id                   :integer          not null, primary key
#  board_name           :string(255)      not null
#  created_at           :datetime
#  updated_at           :datetime
#  certification_number :string(255)      not null
#  expiry_date          :date             not null
#  issue_date           :date             not null
#  specialty            :string(255)      not null
#  doctor_id            :integer          not null
#

FactoryGirl.define do
  factory :board_certification do
    specialty_board = Forgery::Institution.specialty_board
    specialty "Emergency Medicine"  # { specialty_board[:specialty]}
    board_name "American Board of Emergency Medicine" #{ specialty_board[:specialty_board]}
    issue_date { Faker::Time.between(10.years.ago, Time.now) }
    expiry_date { Faker::Time.between(Time.now + 1.month, Time.now + 10.years) }
    certification_number { Faker::Number.number(20)}
  end

end
