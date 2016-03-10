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

require 'rails_helper'

describe FeeRule, focus: true do
  it { should belong_to(:fee_schedule)}

end

describe "fee_rule", focus: true do

  it "should turn 24 hour end times into 23:59" do
    fr = build(:fee_rule, time_of_day_range: "[09:00,24:00)")
    fr.save
    expect(fr.time_of_day_range.end).to eq("23:59")
  end


end
