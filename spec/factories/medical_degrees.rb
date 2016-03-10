# == Schema Information
#
# Table name: medical_degrees
#
#  id           :integer          not null, primary key
#  degree_type  :string(255)      not null
#  awarded_by   :string(255)      not null
#  date_awarded :date             not null
#  created_at   :datetime
#  updated_at   :datetime
#

FactoryGirl.define do
  factory :medical_degree do
    date_awarded { Faker::Time.between(30.years.ago, Time.now) }
    degree_type { Forgery::Degree.medical_degree }
    awarded_by {MedicalSchool.where(country_iso: "US").sample.name}
  end
end
