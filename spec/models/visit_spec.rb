# == Schema Information
#
# Table name: visits
#
#  id             :integer          not null, primary key
#  session_id     :text             not null
#  oncall_time_id :integer          not null
#  patient_id     :integer          not null
#  timerange      :tstzrange        not null
#  fee_paid       :integer          not null
#  duration       :integer          not null
#  jurisdiction   :text             default("not_accepted"), not null
#  authenticated  :string(1)        default("0"), not null
#

require 'rails_helper'

describe "visit", focus:true do
  it "is valid with all attributes filled" do
    visit = build(:visit)
    visit.valid?
    expect(visit).to be_valid
  end

  describe "is invalid without:" do
    fields = %i{ oncall_time_id patient_id timerange authenticated }
    fields.each do |field|
      it "is invalid if #{ field } is nil" do
        credential = build(:visit,
                          field => nil)
        credential.valid?
        expect(credential.errors[field]).to include("can't be blank")
      end
    end
  end

  describe "is invalid with incorrect: " do
    test_array = [['oncall_time_id', 'not_even_a_number', 'is not a number'],
                  ['patient_id', 'not-a-num', 'is not a number'],
                  #['timerange', '1-1-1900 01:01:00 -8:00', 'is not a valid datetime'],
                  ['session_id', '@weird11special$ymbols', 'is invalid'],
                  ['authenticated', 'not_1_or_0', 'is not included in the list']
    ]

    test_array.each do |field_name, field_value, field_error|
        it "is invalid with incorrect #{ field_name }: #{ field_value } " do
          credential = build(:visit,
                      field_name => field_value)
          credential.valid?
          expect(credential.errors[field_name]).to include(field_error)
        end
    end
  end

  describe "timerange" do
    it "is invalid if start is after end" do
      visit = build(:visit,
                   timerange: (Time.now + 6.hours)..(Time.now + 2.hours))
      visit.valid?
      expect(visit.errors[:timerange]).to include("ends before it starts, which is impossible (unless you're a time traveler.) Please try again!")
    end

    it "is invalid if it overlaps an existing visit" do
      visit = build(:visit, timerange: (Time.now + 10.minutes)...(Time.now + 1.hour))
      create(:stripe_customer_with_card, user_id: visit.patient.user.id)
      visit.save
      visit01 = build(:visit, timerange: (Time.now + 20.minutes)...(Time.now + 30.minutes),
                      oncall_time_id: visit.oncall_time.id)

      expect { visit01.valid? }.to raise_error(RuntimeError)
      expect(visit01.errors[:timerange]).to include("We're very sorry, this visit is no longer available. Please book another!")
    end


    it "is not bookable if the timerange is not within the oncall_time" do
      oncall_time = create(:oncall_time, timerange: (Time.now)...(Time.now + 2.hours))
      patient = create(:patient)
      FactoryGirl.create(:stripe_customer_with_card, user_id: patient.user.id)
      expect{create(:visit, oncall_time_id: oncall_time.id,
                    timerange: (Time.now + 110.minutes)...(Time.now + 200.minutes), patient_id: patient.id)
      }.to raise_error(RuntimeError)
    end

  end

  describe "stripe" do
    it "returns an error if the charge is unsuccessful" do
      visit = build(:visit, timerange: (Time.now)...(Time.now + 1.hour))
      StripeCustomer.destroy_all
      FactoryGirl.create(:bad_stripe_customer_with_card, user_id: visit.patient.user.id)

      expect{ visit.save }.to raise_error( RuntimeError )
      expect( visit.errors[:fee_paid] ).not_to be_empty

    end
  end

  describe "is invalid without proper foreign keys:" do
    it "is invalid without an existing oncall_time_id" do
      oncall_time = create(:oncall_time, id: 1)
      user = create(:user)
      visit = build(:visit, oncall_time_id: 2,
                   patient_id: user.id)
      visit.valid?
      expect(visit.errors[:oncall_time_id]).to include("is not a valid oncall time id")
    end

    it "is invalid without an existing patient_id" do
      oncall_time = create(:oncall_time)
      user = create(:user, id: 2)
      visit = build(:visit, oncall_time_id: oncall_time.id,
                   patient_id: 4) # a nonexistent user id
      visit.valid?
      expect(visit.errors[:patient_id]).to include("is not a valid patient id")
    end


    context "Rails Associations" do
      describe Visit do
        it { should belong_to(:oncall_time) }
      end
    end
  end

  describe "PG functions on visit" do
    it "can be updated to record authentication status without the oncall_time being bookable" do
      oncall_time = create(:oncall_time, timerange: (Time.now)...(Time.now + 2.hours))
      patient = create(:patient)
      FactoryGirl.create(:stripe_customer_with_card, user_id: patient.user.id)
      visit = create(:visit, oncall_time_id: oncall_time.id,
                    timerange: (Time.now + 60.minutes)...(Time.now + 90.minutes),
      patient_id: patient.id)

      oncall_time.bookable = false
      oncall_time.save(validate: false)

      expect{ visit.update_columns(authenticated: 1) }.not_to raise_error()
    end
  end
end
