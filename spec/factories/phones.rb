# == Schema Information
#
# Table name: phones
#
#  id         :integer          not null, primary key
#  number     :string(255)      not null
#  phone_type :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#  user_id    :integer          not null
#

FactoryGirl.define do
  factory :phone do
    number { Faker::Number.number(10) }
    phone_type { Forgery::PhoneType.phone_type }
    user_id { FactoryGirl.create(:user).id }
  end

end
