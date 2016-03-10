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

FactoryGirl.define do
  factory :oncall_time do
    association :doctor
    # association :fee_schedule_prefilled
    # need to test for whether a parameter has been passed in, otherwise
    # these callbacks will overwrite the parameter passed in
    #before(:build) do |n|
      #if n.doctor_id.nil?
        #n.doctor_id = FactoryGirl.create(:doctor).id
      #end
    #end
    #before(:create) do |n|
      #if n.doctor_id.nil?
        #n.doctor_id = FactoryGirl.create(:doctor).id
      #end
    #end

    before(:build) do |n|
      if n.fee_schedule_id.nil?
        n.fee_schedule_id = FactoryGirl.create(:fee_schedule_prefilled, doctor_id: n.doctor_id).id
      end
    end
    before(:create) do |n|
      if n.fee_schedule_id.nil?
        n.fee_schedule_id = FactoryGirl.create(:fee_schedule_prefilled, doctor_id: n.doctor_id).id
      end
    end

    timerange       { (Time.now.in_time_zone('US/Pacific') - 1.minute).beginning_of_minute...
                      (Time.now.in_time_zone('US/Pacific') + 6.hours).beginning_of_minute}
    bookable        true # Factory bookable is true, though model bookable default is false
    duration        { if timerange
                        (timerange.end - timerange.begin)
                      end}
     factory :oncall_time_with_online_location do
       after(:create) do |n|
          if n.online_locations.empty?
            FactoryGirl.create(:oncall_times_online_location, oncall_time_id:  n.id)
          end
       end
      end
     factory :oncall_time_with_office_location do
       after(:create) do |n|
          if n.office_locations.empty?
            FactoryGirl.create(:oncall_times_office_location, oncall_time_id:  n.id)
          end
      end
     end
     factory :oncall_time_with_online_and_office_location do
       after(:create) do |n|
          if n.office_locations.empty?
            FactoryGirl.create(:oncall_times_office_location, oncall_time_id:  n.id)
          end
          if n.online_locations.empty?
            FactoryGirl.create(:oncall_times_online_location, oncall_time_id:  n.id)
          end
      end
    end
    end

    # The code below was running even when oncall_time_with_online_location or
     # when oncall_time_with_office_location was called, we may want to add this 
     # back in once we understand FactoryGirl a little better, but for now
     # we can manually add to a blank oncall_time if needed
    # after(:create) do |n|
       #if (n.online_locations.empty? && n.office_locations.empty?)
            #FactoryGirl.create(:oncall_times_online_location, oncall_time_id:  n.id)
            #FactoryGirl.create(:oncall_times_office_location, oncall_time_id:  n.id)
       #end
     #end
  end
