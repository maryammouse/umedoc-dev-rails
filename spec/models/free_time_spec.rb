# == Schema Information
#
# Table name: free_times
#
#  id                   :integer          not null, primary key
#  timerange            :tstzrange        not null
#  oncall_time_id       :integer          not null
#  duration             :integer          not null
#  online_visit_allowed :text             default("not_allowed"), not null
#  office_visit_allowed :text             default("not_allowed"), not null
#  area_visit_allowed   :text             default("not_allowed"), not null
#  online_visit_fee     :decimal(4, )     default(100), not null
#  office_visit_fee     :decimal(4, )     default(100), not null
#  area_visit_fee       :decimal(4, )     default(100), not null
#

require 'rails_helper'

RSpec.describe FreeTime, :type => :model, focus: true do
  # much of the functionality is in db/functions/umedoc_functions.pqsql, and
  # loaded into the db using a migration / db:structure:load
  # but it should be fine to test it here
    describe 'when a new empty oncall_time is created' do
      it 'does not create a new FreeTime if bookable is false' do
        initial_count = FreeTime.count
        oncall_time = FactoryGirl.create(:oncall_time, bookable: false)
        final_count = FreeTime.count
        expect(final_count).to eq(initial_count)
      end
      it 'creates a new FreeTime if bookable is true' do
        initial_count = FreeTime.count

        fee_schedule = FactoryGirl.create(:fee_schedule_prefilled_limited)

        fee_rule_time = FeeRuleTime.where("fee_schedule_id = :fs_id AND
                                          timerange @> (:time_stamp)::timestamptz",
                                          {fs_id: fee_schedule.id,
                                          time_stamp: Time.now.
                                          in_time_zone('US/Pacific').
                                          beginning_of_day +
                                          12.hours }
                                         ).take
        oncall_time = FactoryGirl.create(:oncall_time,
                                          timerange: (Time.now.
                                                        in_time_zone('US/Pacific').
                                                        beginning_of_day +
                                                        6.hours)...
                                                      (Time.now.
                                                        in_time_zone('US/Pacific').
                                                        end_of_day -
                                                        6.hours),
                                          fee_schedule_id: fee_schedule.id,
                                          doctor_id: fee_schedule.doctor_id
                                                        )
        final_count = FreeTime.count
        expect(final_count).to eq(initial_count + 1)
      end

      describe 'the new FreeTime' do
        it 'has the same start time as the parent oncall_time with a 24 hour fee_rule' do
          # uses the default fee_rule factory, which has one rule per day
          # and covers 00:00 to 24:00
          fee_schedule = FactoryGirl.create(:fee_schedule_prefilled)

          fee_rule_time = FeeRuleTime.where("fee_schedule_id = :fs_id AND
                                            timerange @> (:time_stamp)::timestamptz",
                                            {fs_id: fee_schedule.id,
                                            time_stamp: Time.now.
                                            in_time_zone('US/Pacific').
                                            beginning_of_day +
                                            12.hours }
                                           ).take
          oncall_time = FactoryGirl.create(:oncall_time,
                                            timerange: (Time.now.
                                                          in_time_zone('US/Pacific').
                                                          beginning_of_day +
                                                          6.hours)...
                                                        (Time.now.
                                                          in_time_zone('US/Pacific').
                                                          end_of_day -
                                                          6.hours),
                                            fee_schedule_id: fee_schedule.id,
                                            doctor_id: fee_schedule.doctor_id
                                                          )
          free_time = FreeTime.where(oncall_time_id: oncall_time.id).take
          expect(free_time.timerange.begin).to be_within(1.second).of(oncall_time.reload.timerange.begin)
        end
        it 'has the same end time as the parent oncall_time with a 24 hour fee_rule' do
          fee_schedule = FactoryGirl.create(:fee_schedule_prefilled)

          fee_rule_time = FeeRuleTime.where("fee_schedule_id = :fs_id AND
                                            timerange @> (:time_stamp)::timestamptz",
                                            {fs_id: fee_schedule.id,
                                            time_stamp: Time.now.
                                            in_time_zone('US/Pacific').
                                            beginning_of_day +
                                            12.hours }
                                           ).take
          oncall_time = FactoryGirl.create(:oncall_time,
                                            timerange: (Time.now.
                                                          in_time_zone('US/Pacific').
                                                          beginning_of_day +
                                                          6.hours)...
                                                        (Time.now.
                                                          in_time_zone('US/Pacific').
                                                          end_of_day -
                                                          6.hours),
                                            fee_schedule_id: fee_schedule.id,
                                            doctor_id: fee_schedule.doctor_id
                                                          )
          free_time = FreeTime.where(oncall_time_id: oncall_time.id).take
          expect(free_time.reload.timerange.end).to be_within(1.second).of(oncall_time.reload.timerange.end)
        end

        it 'has the same start and end time as the relevant fee_rule_time' do
          fee_schedule = FactoryGirl.create(:fee_schedule_prefilled_limited)

          fee_rule_time = FeeRuleTime.where("fee_schedule_id = :fs_id AND
                                            timerange @> (:time_stamp)::timestamptz",
                                            {fs_id: fee_schedule.id,
                                            time_stamp: Time.now.
                                            in_time_zone('US/Pacific').
                                            beginning_of_day +
                                            12.hours }
                                           ).take
          oncall_time = FactoryGirl.create(:oncall_time,
                                            timerange: (Time.now.
                                                          in_time_zone('US/Pacific').
                                                          beginning_of_day +
                                                          6.hours)...
                                                        (Time.now.
                                                          in_time_zone('US/Pacific').
                                                          end_of_day -
                                                          6.hours),
                                            fee_schedule_id: fee_schedule.id,
                                            doctor_id: fee_schedule.doctor_id
                                                          )
          free_time = FreeTime.where(oncall_time_id: oncall_time.id).take
          expect(free_time.timerange.begin.in_time_zone('US/Pacific')).to be_within(1.second).
            of(fee_rule_time.timerange.begin.in_time_zone('US/Pacific'))
          expect(free_time.timerange.end.in_time_zone('US/Pacific')).to be_within(1.second).
            of(fee_rule_time.timerange.end.in_time_zone('US/Pacific'))
        end
      end
    end


      it 'when an oncall_time is deleted, the associated free_times are deleted' do

          fee_schedule = FactoryGirl.create(:fee_schedule_prefilled_limited)

          fee_rule_time = FeeRuleTime.where("fee_schedule_id = :fs_id AND
                                            timerange @> (:time_stamp)::timestamptz",
                                            {fs_id: fee_schedule.id,
                                            time_stamp: Time.now.
                                            in_time_zone('US/Pacific').
                                            beginning_of_day +
                                            12.hours }
                                           ).take
          oncall_time = FactoryGirl.create(:oncall_time,
                                            timerange: (Time.now.
                                                          in_time_zone('US/Pacific').
                                                          beginning_of_day +
                                                          6.hours)...
                                                        (Time.now.
                                                          in_time_zone('US/Pacific').
                                                          end_of_day -
                                                          6.hours),
                                            fee_schedule_id: fee_schedule.id,
                                            doctor_id: fee_schedule.doctor_id
                                                          )
          initial_count = FreeTime.where(oncall_time_id:oncall_time.id).count
          OncallTime.destroy(oncall_time.id)
          final_count = FreeTime.where(oncall_time_id:oncall_time.id).count
          expect(initial_count - final_count).to eq(1)
      end


      describe 'when a visit is created, the associated free_times' do
        it 'are deleted and recreated' do
          oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now)..(Time.now + 4.hours))
          patient = create(:patient)
          FactoryGirl.create(:stripe_customer_with_card, user_id: patient.user.id)
          visit1 = FactoryGirl.create(:visit_stubbed, patient_id: patient.id,
                                      oncall_time_id: oncall_time.id,
                timerange:(Time.now + 60.minutes)..(Time.now + 75.minutes) )
          free_times = FreeTime.where(oncall_time_id:oncall_time.id)
          initial_free_time_ids = Set.new
          free_times.each {|t| initial_free_time_ids << t.id }

          visit2 = FactoryGirl.create(:visit_stubbed, patient_id: patient.id,
                                      oncall_time_id: oncall_time.id,
                timerange:(Time.now + 120.minutes)..(Time.now + 135.minutes) )
          free_times = FreeTime.where(oncall_time_id:oncall_time.id)
          final_free_time_ids = Set.new
          free_times.each {|t| final_free_time_ids << t.id }
          expect(final_free_time_ids).to satisfy {|t| t.disjoint?(initial_free_time_ids)}
        end

        it 'do not overlap with the visit' do

          fee_schedule = FactoryGirl.create(:fee_schedule_prefilled)

          fee_rule_time = FeeRuleTime.where("fee_schedule_id = :fs_id AND
                                            timerange @> (:time_stamp)::timestamptz",
                                            {fs_id: fee_schedule.id,
                                            time_stamp: Time.now.
                                            in_time_zone('US/Pacific').
                                            beginning_of_day +
                                            12.hours }
                                           ).take
          oncall_time = FactoryGirl.create(:oncall_time,
                                            timerange: (Time.now.
                                                          in_time_zone('US/Pacific').
                                                          beginning_of_day +
                                                          6.hours)...
                                                        (Time.now.
                                                          in_time_zone('US/Pacific').
                                                          end_of_day -
                                                          6.hours),
                                            fee_schedule_id: fee_schedule.id,
                                            doctor_id: fee_schedule.doctor_id
                                                          )
          timerange1 = (Time.now.in_time_zone('US/Pacific').beginning_of_day +
                        11.hours )...
                       (Time.now.in_time_zone('US/Pacific').beginning_of_day +
                        11.hours + 30.minutes)

          patient = create(:patient)
          FactoryGirl.create(:stripe_customer_with_card, user_id: patient.user.id)
          visit = FactoryGirl.create(:visit_stubbed, patient_id: patient.id,
                                     oncall_time_id: oncall_time.id,
                                     timerange: timerange1 )
          free_time1 = FreeTime.where(oncall_time_id:oncall_time.id).order(:timerange).first
          free_time2 = FreeTime.where(oncall_time_id:oncall_time.id).order(:timerange).last
          result =
            (free_time1.timerange.begin == oncall_time.reload.timerange.begin) &&
            (free_time1.timerange.end == visit.reload.timerange.begin) &&
            (free_time2.timerange.begin == visit.reload.timerange.end) &&
            (free_time2.timerange.end == oncall_time.reload.timerange.end)

          expect(result).to eq(true)
        end

        it 'are at least 5 minutes long' do
          oncall_time = FactoryGirl.create(:oncall_time,
                                           timerange:((Time.now + 60.minutes))..((Time.now + 240.minutes)))
          # puts "oncall_time.timerange: #{oncall_time.reload.timerange}"
          timerange1 = (Time.now + 90.minutes)..(Time.now + 105.minutes)
          timerange2 = (Time.now + 110.minutes)..(Time.now + 125.minutes)
          # puts "timerange1: #{timerange1}"
          # puts "timerange2: #{timerange2}"

          patient = create(:patient)
          FactoryGirl.create(:stripe_customer_with_card, user_id: patient.user.id)
          visit1 = FactoryGirl.create(:visit_stubbed, patient_id: patient.id,
                                      oncall_time_id: oncall_time.id,
                                     timerange: timerange1 )
          visit2 = FactoryGirl.create(:visit_stubbed, patient_id: patient.id,
                                      oncall_time_id: oncall_time.id,
                                     timerange: timerange2 )

          # puts "visit1: #{visit1.reload.timerange}"
          # puts "visit2: #{visit2.reload.timerange}"
          free_times = FreeTime.where(oncall_time_id:oncall_time.id)
          # puts "free_times: #{free_times}"
          # free_times.each {|t| puts t.timerange }
          result = true
          free_times.each do |ft|
            result = (result && (ft.timerange.end - ft.timerange.begin) >= 5.minutes)
          end

          expect(result).to eq(true)
        end

        it 'contains the duration in whole seconds' do
          timerange1 = (Time.now + 1.hour).beginning_of_minute..(Time.now+4.hours).beginning_of_minute
          oncall_time = FactoryGirl.create(:oncall_time,
                                           timerange: timerange1,
                                          duration: nil)
          timerange2 = (Time.now + 120.minutes).beginning_of_minute..(Time.now + 135.minutes).beginning_of_minute
          patient = create(:patient)
          FactoryGirl.create(:stripe_customer_with_card, user_id: patient.user.id)
          visit = FactoryGirl.create(:visit_stubbed, patient_id: patient.id,
                                     oncall_time_id: oncall_time.id,
                                     timerange: timerange2,
                                     duration: nil)
          free_time1 = FreeTime.where(oncall_time_id:oncall_time.id).order(:timerange).first
          free_time2 = FreeTime.where(oncall_time_id:oncall_time.id).order(:timerange).last
          db_oncall_time = OncallTime.find(oncall_time.id)
          db_visit = Visit.find(visit.id)
          expect(db_oncall_time.duration).to eq(timerange1.end - timerange1.begin)
          expect(db_visit.duration).to eq(timerange2.end - timerange2.begin)
          expect(free_time1.duration).to eq(free_time1.timerange.end - free_time1.timerange.begin)
          expect(free_time2.duration).to eq(free_time2.timerange.end - free_time2.timerange.begin)
        end
      end

      describe "FreeTime.available" do
        it 'returns a free_time if we are in the middle of one' do
          create(:oncall_time, timerange: (Time.now - 1.hour)..(Time.now + 31.minutes))

          free_times = FreeTime.available
          result = true
          free_times.each do |ft|
            result = (result && (ft.timerange.cover?(Time.now)) )
          end

          expect(result).to eq(true)
        end

        it "returns 3 free_times if 3 doctors are immediately available" do
          FactoryGirl.create_list(:oncall_time, 3, timerange: (Time.now)..(Time.now + 2.hours))

          available_results = FreeTime.available.values.sort.first.count

          expect(available_results).to eq(3)
        end
      end
      describe "FreeTime.next_available" do
        it 'does not return a free_time if available now and not later' do
          fee_schedule = FactoryGirl.create(:fee_schedule_prefilled)

          fee_rule_time = FeeRuleTime.where("fee_schedule_id = :fs_id AND
                                            timerange @> (:time_stamp)::timestamptz",
                                            {fs_id: fee_schedule.id,
                                            time_stamp: Time.now.
                                            in_time_zone('US/Pacific').
                                            beginning_of_day +
                                            12.hours }
                                           ).take
          oncall_time = FactoryGirl.create(:oncall_time,
                                            timerange: (Time.now.
                                                          in_time_zone('US/Pacific').
                                                          beginning_of_day +
                                                          6.hours)...
                                                        (Time.now.
                                                          in_time_zone('US/Pacific').
                                                          end_of_day -
                                                          6.hours),
                                            fee_schedule_id: fee_schedule.id,
                                            doctor_id: fee_schedule.doctor_id
                                                          )
          free_time_ref = FreeTime.find_by(oncall_time_id:oncall_time.id)
          new_time = Time.now.in_time_zone('US/Pacific').beginning_of_day + 6.hours
          Timecop.travel(new_time)
          expect(FreeTime.next_available()).to be_empty
          Timecop.return
        end

        it 'returns 2 free_times if only 1 of 3 is immediately available' do
          new_time = Time.now.in_time_zone('US/Pacific').beginning_of_day + 6.hours
          Timecop.travel(new_time)
          timerange1 = (new_time - 2.hours).beginning_of_minute..(new_time + 90.minutes).beginning_of_minute
          timerange2 = (new_time + 2.hours).beginning_of_minute..(new_time + 3.hours).beginning_of_minute
          timerange3 = (new_time + 2.hours).beginning_of_minute..(new_time + 3.hours).beginning_of_minute
          oncall_time1 = FactoryGirl.create(:oncall_time,
                                           timerange: timerange1)
          oncall_time2 = FactoryGirl.create(:oncall_time,
                                           timerange: timerange2)
          oncall_time3 = FactoryGirl.create(:oncall_time,
                                           timerange: timerange3)

          result = FreeTime.next_available
          free_time1 = FreeTime.find_by(oncall_time_id: oncall_time1.id)
          free_time2 = FreeTime.find_by(oncall_time_id: oncall_time2.id)
          free_time3 = FreeTime.find_by(oncall_time_id: oncall_time3.id)

          expect(result.values.sort.first.count).to eq(2)
          Timecop.return
        end

        it "returns 0 free_times if 3 of 3 doctors are only available now" do
          new_time = Time.now.in_time_zone('US/Pacific').beginning_of_day + 6.hours
          Timecop.travel(new_time)
          oncall_times_ary = FactoryGirl.create_list(:oncall_time, 3, timerange: (new_time)...(new_time + 2.hours))
          free_times_ref_set = Set.new
          oncall_times_ary.each do |n|
            free_times_ref_set << FreeTime.find_by(oncall_time_id: n.id)
          end

          query_results = FreeTime.next_available()

          expect(query_results.to_set).to satisfy { |t| t.disjoint?(free_times_ref_set) }
          Timecop.return
        end

        it "returns 3 free_times if 3 of 3 doctors are available later" do
          new_time = Time.now.in_time_zone('US/Pacific').beginning_of_day + 6.hours
          Timecop.travel(new_time)
          FactoryGirl.create_list(:oncall_time, 3, timerange: (new_time + 1.hour)..(new_time + 2.hours))

          query_results = FreeTime.next_available()

          expect(query_results.values.sort.first.count).to eq(3)
          Timecop.return
        end

        it "has no elements in common with FreeTime.available" do
          new_time = Time.now.in_time_zone('US/Pacific').beginning_of_day + 6.hours
          Timecop.travel(new_time)
          oncall_time1 = create(:oncall_time, timerange: (new_time - 1.hour)..(new_time + 5.hours))
          oncall_time2 = create(:oncall_time, timerange: (new_time + 1.hour)..(new_time + 2.hours))

          available = FreeTime.available

          available_ary = []
          available.each do |n|
            available_ary << n
          end

          next_available = FreeTime.next_available

          next_available_ary = []
          next_available.each do |n|
            next_available_ary << n
          end

          next_available.each do |n|
            expect(available).not_to include n
          end
          Timecop.return
        end
      end

      context "Model Associations" do
        describe FreeTime do
          it { should belong_to(:oncall_time) }
          it { should have_one(:doctor).through(:oncall_time)}
        end
      end
end
