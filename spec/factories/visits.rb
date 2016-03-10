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

FactoryGirl.define do
  factory :visit do
    association :oncall_time
    association :patient
      sequence :timerange do |n|
        (Time.now + n.minutes).round_off(5.minutes)...
          (Time.now + (n+5).minutes).round_off(5.minutes)
      end
    jurisdiction 'accepted'
    #oncall_time_id { FactoryGirl.create(:oncall_time).id }

    #patient_id { FactoryGirl.create(:patient).id }
    session_id { OPENTOK.create_session(:media_route=> :routed).session_id }
    fee_paid 5000
    duration        { if timerange
                      (timerange.end - timerange.begin)
                    end}
    authenticated '0'

    factory :visit_stubbed do
      sequence :session_id do |n|
        n
      end
      timerange { (Time.now + 60.minutes).beginning_of_minute..(Time.now + 75.minutes).beginning_of_minute }
    end
  end
end

