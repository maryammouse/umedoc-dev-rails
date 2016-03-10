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

require 'rails_helper'

RSpec.describe FeeRuleTime, :type => :model do
  describe FeeRuleTime do
    it { should belong_to(:fee_schedule) }

    describe "when there are no FeeRules" do
      it 'there are no FeeRuleTimes' do
        FactoryGirl.create(:fee_rule)
        FeeRule.destroy_all
        expect(FeeRule.count).to eq(0)
        expect(FeeRuleTime.count).to eq(0)
      end
    end
    describe "when a FeeRule is created" do
      it 'a set of FeeRuleTimes should be created' do
        FactoryGirl.create(:fee_rule)
        expect(FeeRuleTime.count).to eq(4)
      end

      it 'the fee, timerange, visit_duration, online_visit_allowed and office_visit_allowed of the FeeRuleTimes
        should correspond to the FeeRule' do
        fs = FactoryGirl.create(:fee_schedule)
        dow1 = 1
        dow2 = 2
        fee_1 = 50
        fee_2 = 100
        visit_duration_1 = '00:15:00'
        visit_duration_2 = '00:45:00'
        online_visit_allowed_2 = 'not_allowed'
        office_visit_allowed_2 = 'allowed'
        fee_rule1 = FactoryGirl.create(:fee_rule, fee_schedule_id: fs.id,
                                       day_of_week: dow1,
                                       time_of_day_range: Time.parse('2000-01-01 10:30:00 UTC')...
                                           Time.parse('2000-01-01 11:30:00 UTC'),
                                       fee: fee_1,
                                       duration: visit_duration_1)
        fee_rule2 = FactoryGirl.create(:fee_rule, fee_schedule_id: fs.id,
                                       day_of_week: dow2,
                                       time_of_day_range: Time.parse('2000-01-01 20:45:00')...
                                           Time.parse('2000-01-01 21:15:00'),
                                       fee: fee_2,
                                       duration: visit_duration_2,
                                       online_visit_allowed: 'not_allowed',
                                       office_visit_allowed: 'allowed')
        frt1 = FeeRuleTime.where("fee_schedule_id = :fee_schedule_id and 
                                  extract(dow from (lower(timerange) at time zone (:tzone)))= :dow ",
                                  { fee_schedule_id: fs.id,
                                    dow: dow1,
                                    tzone: fee_rule1.fee_schedule.time_zone}).first
        frt2 = FeeRuleTime.where("fee_schedule_id = :fee_schedule_id and 
                                  extract(dow from (lower(timerange) at time zone (:tzone)))= :dow ",
                                  { fee_schedule_id: fs.id,
                                    dow: dow2,
                                    tzone: fee_rule2.fee_schedule.time_zone}).first

        start_time_1 = frt1.timerange.begin.in_time_zone(fee_rule1.fee_schedule.time_zone)
        end_time_1 = frt1.timerange.end.in_time_zone(fee_rule1.fee_schedule.time_zone)
        frt_fee_1 = frt1.fee
        frt_visit_duration_1 = frt1.visit_duration
        frt_online_visit_allowed_1 = frt1.online_visit_allowed
        frt_office_visit_allowed_1 = frt1.office_visit_allowed
        start_time_2 = frt2.timerange.begin.in_time_zone(fee_rule2.fee_schedule.time_zone)
        end_time_2 = frt2.timerange.end.in_time_zone(fee_rule2.fee_schedule.time_zone)
        frt_fee_2 = frt2.fee
        frt_visit_duration_2 = frt2.visit_duration
        frt_online_visit_allowed_2 = frt2.online_visit_allowed
        frt_office_visit_allowed_2 = frt2.office_visit_allowed
        expect(start_time_1.strftime('%H:%M')).to eq(fee_rule1.time_of_day_range.begin.strftime('%H:%M'))
        expect(end_time_1.strftime('%H:%M')).to eq(fee_rule1.time_of_day_range.end.strftime('%H:%M'))
        expect(start_time_2.strftime('%H:%M')).to eq(fee_rule2.time_of_day_range.begin.strftime('%H:%M'))
        expect(end_time_2.strftime('%H:%M')).to eq(fee_rule2.time_of_day_range.end.strftime('%H:%M'))
        expect(frt_fee_1).to eq(fee_1)
        expect(frt_fee_2).to eq(fee_2)
        expect(frt_visit_duration_1).to eq(visit_duration_1)
        expect(frt_visit_duration_2).to eq(visit_duration_2)
        expect(frt_online_visit_allowed_1).to eq('allowed') #using factory defaults
        expect(frt_office_visit_allowed_1).to eq('allowed') #using factory defaults
        expect(frt_online_visit_allowed_2).to eq('not_allowed')
        expect(frt_office_visit_allowed_2).to eq('allowed')
      end

      it 'when a new fee_rule is created for a fee_schedule_id,
        the associated fee_rule_times are deleted and regenerated' do
       fee_rule_1 = FactoryGirl.create(:fee_rule)
       fee_rule_times = FeeRuleTime.where(fee_schedule_id: fee_rule_1.fee_schedule_id)
       initial_fee_rule_time_ids = Set.new
       fee_rule_times.each {|t| initial_fee_rule_time_ids << t.id }

       fee_rule_2= FactoryGirl.create(:fee_rule, fee_schedule_id:fee_rule_1.fee_schedule_id)
       fee_rule_times = FeeRuleTime.where(fee_schedule_id:  fee_rule_2.fee_schedule_id)
       final_fee_rule_time_ids = Set.new
       fee_rule_times.each {|t| final_fee_rule_time_ids << t.id }
       expect(final_fee_rule_time_ids).to satisfy {|t| t.disjoint?(initial_fee_rule_time_ids)}
     end




    end
  end
end
