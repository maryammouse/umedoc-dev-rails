# == Schema Information
#
# Table name: doctors
#
#  id                  :integer          not null, primary key
#  user_id             :integer          not null
#  verification_status :text             default("not_verified"), not null
#  blurb               :text
#  linked_in           :string(255)
#  image               :text
#

FactoryGirl.define do
  factory :doctor do
    user
    #user_id { FactoryGirl.create(:user).id }
    verification_status 'verified'
    blurb 'I am a doctor and Im Ahmazing'
    linked_in 'Blah'

    after(:create) do |n|
      if n.medical_licenses.empty?
      FactoryGirl.create(:medical_license, doctor_id:n.id)
      end
      if n.stripe_seller.nil?
      FactoryGirl.create(:stripe_seller, user_id:n.user.id)
      end
    end
  end
end
