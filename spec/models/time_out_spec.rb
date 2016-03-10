# == Schema Information
#
# Table name: time_outs
#
#  timerange      :tstzrange        not null
#  oncall_time_id :integer          not null
#  id             :integer          not null, primary key
#

require 'rails_helper'

RSpec.describe TimeOut, :type => :model do
  describe TimeOut do
    it { should belong_to( :oncall_time ) }

    it "should create a new time_out" do
      oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now)...
                                       (Time.now+4.hours))
      initial_count = TimeOut.count
      FactoryGirl.create(:time_out,
                         timerange: (Time.now + 120.minutes)...
                         (Time.now + 150.minutes),
                         oncall_time_id: oncall_time.id )
      final_count = TimeOut.count

      expect(final_count).to eq(initial_count + 1)
    end

    it "should not create a new time_out unless it is contained within an oncall_time" do

      oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now)...
                                       (Time.now+ 240.minutes))
      expect{FactoryGirl.create(:time_out, timerange:(Time.now + 210.minutes)...
                                    (Time.now+250.minutes),
                                oncall_time_id: oncall_time.id )}.
                                to raise_error(ActiveRecord::StatementInvalid)
    end


    it "should not create a new time_out when a visit overlaps that time" do

      oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now)...
                                       (Time.now+4.hours))
      patient = create(:patient)
      FactoryGirl.create(:stripe_customer_with_card, user_id: patient.user.id)
      visit = FactoryGirl.create(:visit, patient_id: patient.id,
                                 timerange:(Time.now + 1.hour)...
                                 (Time.now+90.minutes),
                                oncall_time_id: oncall_time.id )
      expect{FactoryGirl.create(:time_out, timerange:(Time.now + 80.minutes)...
                                    (Time.now+140.minutes),
                                oncall_time_id: oncall_time.id )}.
                                to raise_error(ActiveRecord::StatementInvalid)
    end

    it "should not create a new time_out when another time_out overlaps that time" do

      oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now)...
                                       (Time.now+4.hours))
      time_out_1 = FactoryGirl.create(:time_out, timerange:(Time.now + 1.hour)...
                                 (Time.now+90.minutes),
                                oncall_time_id: oncall_time.id )
      expect{FactoryGirl.create(:time_out, timerange:(Time.now + 80.minutes)...
                                    (Time.now+140.minutes),
                                oncall_time_id: oncall_time.id )}.
                                to raise_error(ActiveRecord::StatementInvalid)
    end

    context "when it creates a time_out, there should be no overlap between the free_times, visits, or time_outs" do
      it 'when the time_out.timerange.begin equals the free_time.timerange.begin ' do

      oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now)...
                                       (Time.now+4.hours))
      patient = FactoryGirl.create(:patient)
      FactoryGirl.create(:stripe_customer_with_card, user_id: patient.user.id)
      visit_1 = FactoryGirl.create(:visit, patient_id: patient.id,
                                   timerange:(Time.now + 60.minutes )...
                                 (Time.now+90.minutes),
                                oncall_time_id: oncall_time.id )
      visit_2 = FactoryGirl.create(:visit, patient_id: patient.id,
                                   timerange:(Time.now + 120.minutes )...
                                 (Time.now+150.minutes),
                                oncall_time_id: oncall_time.id )
      time_out_1 = FactoryGirl.create(:time_out, timerange:(Time.now + 150.minutes )...
                                 (Time.now+180.minutes),
                                oncall_time_id: oncall_time.id )
      overlap_free_times_time_out = FreeTime.where(oncall_time_id: oncall_time.id).
        where("free_times.timerange && tstzrange(:start_time,:end_time)",
                                    {start_time: time_out_1.reload.timerange.begin,
                                     end_time: time_out_1.reload.timerange.end } )
      overlap_free_times_visit1 = FreeTime.where(oncall_time_id: oncall_time.id).
        where("free_times.timerange && tstzrange(:start_time,:end_time)",
                                    {start_time: visit_1.reload.timerange.begin,
                                     end_time: visit_1.reload.timerange.end } )
      overlap_free_times_visit2 = FreeTime.where(oncall_time_id: oncall_time.id).
        where("free_times.timerange && tstzrange(:start_time,:end_time)",
                                    {start_time: visit_2.reload.timerange.begin,
                                     end_time: visit_2.reload.timerange.end } )
      overlap_visits_time_out = Visit.where(oncall_time_id: oncall_time.id).
        where("visits.timerange && tstzrange(:start_time, :end_time)",
                                    {start_time: time_out_1.reload.timerange.begin,
                                     end_time:   time_out_1.reload.timerange.end })

      expect(overlap_free_times_time_out.count ).to eq(0)
      expect(overlap_free_times_visit1.count).to eq(0)
      expect(overlap_free_times_visit2.count).to eq(0)
      expect(overlap_visits_time_out.count).to eq(0)
      end


      it 'when the time_out.timerange.end equals the free_time.timerange.end ' do

      oncall_time = FactoryGirl.create(:oncall_time, timerange:(Time.now)...
                                       (Time.now+4.hours))
      patient = create(:patient)
      FactoryGirl.create(:stripe_customer_with_card, user_id: patient.user.id)
      visit_1 = FactoryGirl.create(:visit, patient_id: patient.id,
                                   timerange:(Time.now + 60.minutes )...
                                 (Time.now+90.minutes),
                                oncall_time_id: oncall_time.id )
      visit_2 = FactoryGirl.create(:visit, patient_id: patient.id,
                                   timerange:(Time.now + 120.minutes )...
                                 (Time.now+150.minutes),
                                oncall_time_id: oncall_time.id )
      time_out_1 = FactoryGirl.create(:time_out, timerange:(Time.now + 210.minutes )...
                                 (Time.now+240.minutes),
                                oncall_time_id: oncall_time.id )
      overlap_free_times_time_out = FreeTime.where(oncall_time_id: oncall_time.id).
        where("free_times.timerange && tstzrange(:start_time,:end_time)",
                                    {start_time: time_out_1.reload.timerange.begin,
                                     end_time: time_out_1.reload.timerange.end } )
      overlap_free_times_visit1 = FreeTime.where(oncall_time_id: oncall_time.id).
        where("free_times.timerange && tstzrange(:start_time,:end_time)",
                                    {start_time: visit_1.reload.timerange.begin,
                                     end_time: visit_1.reload.timerange.end } )
      overlap_free_times_visit2 = FreeTime.where(oncall_time_id: oncall_time.id).
        where("free_times.timerange && tstzrange(:start_time,:end_time)",
                                    {start_time: visit_2.reload.timerange.begin,
                                     end_time: visit_2.reload.timerange.end } )
      overlap_visits_time_out = Visit.where(oncall_time_id: oncall_time.id).
        where("visits.timerange && tstzrange(:start_time, :end_time)",
                                    {start_time: time_out_1.reload.timerange.begin,
                                     end_time:   time_out_1.reload.timerange.end })

      expect(overlap_free_times_time_out.count ).to eq(0)
      expect(overlap_free_times_visit1.count).to eq(0)
      expect(overlap_free_times_visit2.count).to eq(0)
      expect(overlap_visits_time_out.count).to eq(0)
      end

    end

  end
end
