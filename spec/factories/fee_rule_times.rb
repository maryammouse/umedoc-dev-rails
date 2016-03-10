# == Schema Information
#
# Table name: fee_rule_times
#
#  id                   :integer          not null, primary key
#  fee_schedule_id      :integer          not null
#  timerange            :tstzrange        not null
#  fee                  :decimal(4, )     not null
#  visit_duration       :string           default("00:30:00")
#  online_visit_allowed :text             default("not_allowed"), not null
#  office_visit_allowed :text             default("not_allowed"), not null
#  area_visit_allowed   :text             default("not_allowed"), not null
#  online_visit_fee     :decimal(4, )     default(100), not null
#  office_visit_fee     :decimal(4, )     default(100), not null
#  area_visit_fee       :decimal(4, )     default(100), not null
#

FactoryGirl.define do
  factory :fee_rule_time do
    
  end

end
