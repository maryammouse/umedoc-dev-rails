# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  firstname              :string(255)      not null
#  lastname               :string(255)      not null
#  dob                    :date             not null
#  created_at             :datetime
#  updated_at             :datetime
#  gender                 :string(255)      not null
#  username               :string(255)      not null
#  password_digest        :string(255)      not null
#  authy_id               :string(255)      not null
#  cellphone              :string(50)       not null
#  country_code           :string(5)        default("1"), not null
#  slug                   :text
#  password_reset_token   :string
#  password_reset_sent_at :datetime
#

FactoryGirl.define do

  factory :user do
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    dob { Faker::Date.between(115.years.ago, 18.years.ago) }
    authy_id {  Faker::Number.number(10) }
    cellphone { "3103846240" }
    country_code {"1"}
    gender { ["male", "female", "other"].sample }
    username { Faker::Internet.email }
    password { 'badpw' }

    after(:create) do |n|
      FactoryGirl.create(:stripe_customer_with_card,  user_id: n.id)
    end

    factory :user_stripe_customer do |n|
      after(:create) do
        FactoryGirl.create(:stripe_customer_with_card,  user_id: n.id)
      end
    end


    #id { Faker::Number.digit }
  end

end
