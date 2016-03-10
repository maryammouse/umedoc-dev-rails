# == Schema Information
#
# Table name: promotions
#
#  discount             :integer          not null
#  max_uses_per_patient :integer          not null
#  name                 :string(255)
#  promo_code           :string(255)      not null
#  id                   :integer          not null, primary key
#  timezone             :text             default("Pacific Time (US & Canada)"), not null
#  doctor_id            :integer          not null
#  applicable_timerange :tstzrange        not null
#  bookable_timerange   :tstzrange        not null
#  applicable           :text             not null
#  bookable             :text             not null
#  discount_type        :text             not null
#

FactoryGirl.define do
  factory :promotion do
    name 'Free visits and shit'
    doctor_id { FactoryGirl.create(:doctor).id }
    discount { rand(1...100) }
    discount_type {['percentage', 'fixed'].sample}
    applicable 'applicable'
    bookable 'bookable'
    timezone 'Pacific Time (US & Canada)'
    applicable_timerange   { (Time.now.in_time_zone('US/Pacific') - 10.minutes).beginning_of_minute...
                  (Time.now.in_time_zone('US/Pacific') + 6.days).beginning_of_minute}
    bookable_timerange   { (Time.now.in_time_zone('US/Pacific') - 10.minutes).beginning_of_minute...
                  (Time.now.in_time_zone('US/Pacific') + 6.months).beginning_of_minute}
    max_uses_per_patient { rand(1..10) }
    promo_code { (1..6).map { SecureRandom.base64.gsub(/-*\+*\/*\-*\_*\=*/,'').split('').sample }.join }
  end

end
