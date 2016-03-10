# == Schema Information
#
# Table name: oncall_times
#
#  id              :integer          not null, primary key
#  doctor_id       :integer          not null
#  fee_schedule_id :integer          not null
#  timerange       :tstzrange        not null
#  bookable        :boolean          default(FALSE), not null
#  duration        :integer          not null
#

require 'rails_helper'

RSpec.describe OncallTime, :type => :model, :focus => true do

  describe OncallTime do
    it { should belong_to(:doctor) }
    it { should have_many(:visits) }
    it { should have_many(:time_outs) }
    it { should have_many(:free_times) }
    it { should belong_to(:fee_schedule) }
    it { should have_many(:online_locations) }

    it "is valid with a doctor_id, fee_schedule, tstzrange" do
      oncall_time =  FactoryGirl.create(:oncall_time)
      expect(oncall_time.errors).to be_empty
      # calling .valid? OR using expect(blah).to be_valid runs validations again
      # so overlapvalidator will fail because of PRIOR successful save
    end

    it "is invalid without a doctor_id" do
      oncall_time =  FactoryGirl.build(:oncall_time, doctor_id:nil)
      oncall_time.valid?
      expect(oncall_time.errors[:doctor_id]).to include("can't be blank")
    end

    it "is invalid without a fee_schedule_id" do
      oncall_time =  FactoryGirl.build(:oncall_time, fee_schedule_id:nil)
      oncall_time.valid?
      expect(oncall_time.errors[:fee_schedule_id]).to include("can't be blank")
    end

    it "is invalid without a timerange" do
      oncall_time =  FactoryGirl.build(:oncall_time, timerange:nil)
      oncall_time.valid?
      expect(oncall_time.errors[:timerange]).to include("can't be blank")
    end

    it "is invalid with an overlapping time for a given doctor_id" do
      doc = FactoryGirl.create(:doctor)
      fee_sch = FactoryGirl.create(:fee_schedule, doctor_id:doc.id)
      oncall_time_1 = FactoryGirl.create(:oncall_time, doctor_id:doc.id, fee_schedule_id:fee_sch.id)
      oncall_time_2 = FactoryGirl.build(:oncall_time, doctor_id:doc.id, fee_schedule_id:fee_sch.id)
      oncall_time_2.valid?
      expect(oncall_time_2.errors[:timerange]).to include("can't overlap an existing timerange")
    end

    it "is valid with an non_overlapping time for a given doctor_id" do
      doc = FactoryGirl.create(:doctor)
      fee_sch = FactoryGirl.create(:fee_schedule, doctor_id:doc.id)
      oncall_time_1 = FactoryGirl.create(:oncall_time, doctor_id:doc.id, fee_schedule_id:fee_sch.id)
      oncall_time_2 = FactoryGirl.build(:oncall_time, doctor_id:doc.id, fee_schedule_id:fee_sch.id,
             timerange:(Time.now+12.hours)..(Time.now+14.hours))
      oncall_time_2.valid?
      expect(oncall_time_2).to be_valid
    end


  end
end
