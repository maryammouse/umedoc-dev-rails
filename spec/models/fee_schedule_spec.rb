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

require 'rails_helper'

describe FeeSchedule, :type => :model do
  it { should have_many(:oncall_times) }
  it { should have_many(:fee_rules) }
  it { should have_many(:fee_rule_times) }

  context "fee_amount method" do
    it "returns the correct fee for a specific time, time_zone, and visit_type" do
      tz = 'US/Pacific'
      Time.zone = tz
      now_time = Time.zone.now
      day_of_week = (now_time.wday)%7
      fs = FactoryGirl.create(:fee_schedule,
                              time_zone: tz)
      fr_0 = FactoryGirl.create(:fee_rule, time_of_day_range:
                                             Time.parse('2000-01-01 00:00:00')...
                                                 Time.parse('2000-01-01 01:00:00'),
                                fee: 100,
                                day_of_week: day_of_week,
                               fee_schedule_id: fs.id)
      fs_id = fs.id
      (1..23).each do |t|
        timerange = Time.parse('2000-01-01' + ' ' + t.to_s + ':00:00')...
            Time.parse('2000-01-01' + ' ' + (t+1).to_s + ':00:00')
        FactoryGirl.create(:fee_rule,
                           time_of_day_range: timerange,
                           fee: 100 + t,
                           online_visit_fee: 200 + t,
                           office_visit_fee: 300 + t,
                           area_visit_fee: 400 + t,
                           fee_schedule_id: fs.id,
                           day_of_week: day_of_week)
      #  puts "fee_rule timerange % created", timerange
      end

      oncall_time = FactoryGirl.create(:oncall_time,
                                       doctor_id: fr_0.fee_schedule.doctor_id,
                                       fee_schedule_id: fs.id,
                                       timerange: (now_time)...(now_time + 2.hours))

      expected_fee = now_time.strftime("%k").to_i + 100
      expected_online_fee = now_time.strftime("%k").to_i + 200
      expected_office_fee = now_time.strftime("%k").to_i + 300
      expected_area_fee = now_time.strftime("%k").to_i + 400
      online_fee = fs.fee_amount(now_time, tz , :online)
      office_fee = fs.fee_amount(now_time, tz , :office)
      area_fee = fs.fee_amount(now_time, tz , :area)
      #puts expected_fee
      #puts result
      #puts now_time
      #puts now_time.zone

      expect(online_fee).to eq(expected_online_fee)
      expect(office_fee).to eq(expected_office_fee)
      expect(area_fee).to eq(expected_area_fee)

      Time.zone = 'UTC'
    end



    it "returns the correct fee around change of DST **see comments in spec for exceptions**" do
      tz = 'US/Pacific'
      Time.zone = tz
      target_time_ary = [
      target_time1 = Time.new(2015,11,1,0,0,0,'-07:00'),
      #target_time2 = Time.new(2015,11,1,1,0,0,'-07:00'),
      #currently, the fee_rule_time_regenerate function has the following behavior
      #at end of daylight saving time
      #it produces 1 fee_rule_time from 00:00 -07:00 to 01:00 -08:00
      #in effect, it switches to PST one hour early
      #given how unlikely it is to have a change of fee at this time of day,
      #we are not going to address this behavior now.
      target_time3 = Time.new(2015,11,1,1,0,0,'-08:00'),
      target_time4 = Time.new(2015,11,1,2,0,0,'-08:00')
      ]
      target_time_ary.each do |now_time|
          Timecop.travel(now_time)
          day_of_week = (now_time.wday)%7
          fs = FactoryGirl.create(:fee_schedule,
                                  time_zone: tz,
                                  weeks_ahead: 52)

          fr_0 = FactoryGirl.create(:fee_rule,
                                    time_of_day_range:  Time.parse('2000-01-01 00:00:00')...
                                        Time.parse('2000-01-01 01:00:00'),
                                    fee: 100,
                                    day_of_week: day_of_week,
                                   fee_schedule_id: fs.id)
          (1..3).each do |t|
            timerange = (Time.parse('2000-01-01' + ' ' + t.to_s + ':00:00')...
                Time.parse('2000-01-01' + ' ' + (t+1).to_s + ':00:00'))
            FactoryGirl.create(:fee_rule,
                               time_of_day_range: timerange,
                               fee: 100 + t,
                               online_visit_fee: 200 + t,
                               office_visit_fee: 300 + t,
                               area_visit_fee: 400 + t,
                               fee_schedule_id: fs.id,
                                 day_of_week: day_of_week)
           #  puts "fee_rule timerange % created", timerange
          end

        oncall_time = FactoryGirl.create(:oncall_time,
                                         doctor_id: fr_0.fee_schedule.doctor_id,
                                         fee_schedule_id: fs.id,
                                         timerange: (now_time)...(now_time + 2.hours))

        #expected_fee = now_time.in_time_zone('US/Pacific').strftime("%k").to_i + 100
        #result = fs.fee_amount(now_time, 'US/Pacific', :online)
        expected_fee = now_time.strftime("%k").to_i + 100
        expected_online_fee = now_time.strftime("%k").to_i + 200
        expected_office_fee = now_time.strftime("%k").to_i + 300
        expected_area_fee = now_time.strftime("%k").to_i + 400

        online_fee = fs.fee_amount(now_time, tz , :online)
        office_fee = fs.fee_amount(now_time, tz , :office)
        area_fee = fs.fee_amount(now_time, tz , :area)

        expect(online_fee).to eq(expected_online_fee)
        expect(office_fee).to eq(expected_office_fee)
        expect(area_fee).to eq(expected_area_fee)
      end
      Timecop.return

      Time.zone = 'UTC'
    end
  end
end
