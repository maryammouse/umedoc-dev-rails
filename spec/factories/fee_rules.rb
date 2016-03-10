# == Schema Information
#
# Table name: fee_rules
#
#  id                   :integer          not null, primary key
#  day_of_week          :integer          not null
#  fee                  :decimal(4, )     not null
#  duration             :string           default("00:30:00"), not null
#  fee_schedule_id      :integer          not null
#  time_of_day_range    :timerange        not null
#  online_visit_allowed :text             default("not_allowed"), not null
#  office_visit_allowed :text             default("not_allowed"), not null
#  area_visit_allowed   :text             default("not_allowed"), not null
#  online_visit_fee     :decimal(4, )     default(100), not null
#  office_visit_fee     :decimal(4, )     default(100), not null
#  area_visit_fee       :decimal(4, )     default(100), not null
#

FactoryGirl.define do
  factory :fee_rule do
      association :fee_schedule
      sequence(:day_of_week) { |n| n%7 }
      time_of_day_range  Time.parse("2000-01-01 00:00:00 UTC")...Time.parse("2000-01-01 24:00:00 UTC")
      fee    { |n| n.day_of_week * 10 + 100 }
      online_visit_fee  {|n| n.day_of_week * 10 + 200 }
      office_visit_fee {|n| n.day_of_week * 10 + 300 }
      area_visit_fee {|n| n.day_of_week * 10 + 400 }
      #fee_schedule_id  { FactoryGirl.create(:fee_schedule).id }
      online_visit_allowed 'allowed'
      office_visit_allowed 'allowed'
      factory :fee_rule_mini do
        duration 10.minutes
      end
      factory :fee_rule_limited do
        time_of_day_range Time.parse('2001-01-01 10:00:00 UTC')...Time.parse('2001-01-01 14:00:00')
      end

  end



#  factory :fee_rule do
    #association :fee_schedule
    #sequence(:day_of_week) { |n| n%7 }
    #time_of_day_range  '00:00'...'24:00'
    #fee    { |n| n.day_of_week * 10 + 100 }
    #online_visit_fee  {|n| n.day_of_week * 10 + 200 }
    #office_visit_fee {|n| n.day_of_week * 10 + 300 }
  #end

end
