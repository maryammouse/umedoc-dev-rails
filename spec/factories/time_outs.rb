# == Schema Information
#
# Table name: time_outs
#
#  timerange      :tstzrange        not null
#  oncall_time_id :integer          not null
#  id             :integer          not null, primary key
#

FactoryGirl.define do
  factory :time_out do
    oncall_time_id { FactoryGirl.create(
      :oncall_time_with_online_and_office_location ).id }
    timerange { (Time.now + 1.hour )...
                (Time.now + 2.hour ) }
  end

end
