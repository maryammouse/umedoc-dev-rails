class VisitNotificationJob < ActiveJob::Base
  include TwilioSms

  queue_as :default

  def perform(visit)
    visit_time_zone = visit.oncall_time.fee_schedule.time_zone
    start_time = visit.timerange.begin.in_time_zone(visit_time_zone)
    patient_name = visit.patient.user.firstname + " " +
                   visit.patient.user.lastname
    patient_cellphone = "+" +
                        visit.patient.user.country_code +
                        visit.patient.user.cellphone
    doctor_cellphone = "+" +
                        visit.oncall_time.doctor.user.country_code +
                        visit.oncall_time.doctor.user.cellphone
    doctor_name = visit.oncall_time.doctor.user.lastname
    send_sms(doctor_cellphone,
             "Dr #{doctor_name} you have a visit starting at #{start_time} with patient #{patient_name} at cellphone number #{patient_cellphone}")
  end
end
