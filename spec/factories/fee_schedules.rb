# == Schema Information
#
# Table name: fee_schedules
#
#  doctor_id   :integer          not null
#  id          :integer          not null, primary key
#  name        :string           default("Default"), not null
#  time_zone   :text             default("US/Pacific"), not null
#  weeks_ahead :integer          default(4), not null
#

FactoryGirl.define do
  factory :fee_schedule do
    association :doctor
    #doctor_id  { FactoryGirl.create(:doctor).id }

    factory :fee_schedule_prefilled do
      after(:create) do |n|
          if n.fee_rules.empty?
            FactoryGirl.create_list(:fee_rule, 7, fee_schedule_id:  n.id)
          end
      end
    end
    factory :fee_schedule_prefilled_mini do
      after(:create) do |n|
          if n.fee_rules.empty?
            FactoryGirl.create_list(:fee_rule_mini, 7, fee_schedule_id:  n.id)
          end
      end
    end
    factory :fee_schedule_prefilled_limited do
          after(:create) do |n|
              if n.fee_rules.empty?
                FactoryGirl.create_list(:fee_rule_limited, 7, fee_schedule_id:  n.id)
              end
          end
    end
  end
end
