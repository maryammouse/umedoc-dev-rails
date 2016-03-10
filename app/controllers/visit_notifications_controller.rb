# if Time.now == visit.start - 15.minutes
  # send twilio sms to patient and doctor

class  VisitNotificationsController < ApplicationController
  # Visit.where('lower(timerange)=:query_time', {query_time: (Time.now + 15.minutes).beginning_of_minute})
  def visit_sms

    visits_5 = Visit.where('lower(timerange)=:query_time', {query_time: (Time.now + 5.minutes).beginning_of_minute})
    visits_15 = Visit.where('lower(timerange)=:query_time', {query_time: (Time.now + 15.minutes).beginning_of_minute})
    visits_30 = Visit.where('lower(timerange)=:query_time', {query_time: (Time.now + 30.minutes).beginning_of_minute})

    visits_5.each do |v|
      doctor_cellphone = '+' + v.oncall_time.doctor.user.country_code+v.oncall_time.doctor.user.cellphone
      doctor_name = v.oncall_time.doctor.user.lastname
      patient_name = v.patient.user.firstname + ' ' + v.patient.user.lastname
      patient_cellphone = '+' + v.patient.user.country_code + v.patient.user.cellphone
      v.send_sms(doctor_cellphone,
                 "Hi Doctor #{doctor_name}, you have a visit at #{v.timerange.begin} with patient #{patient_name}, whose cell number is #{patient_cellphone}.")
      puts "message sent"
      Rails.logger.info "sms requested t-5: doctor_name: #{doctor_name}, doctor_cellphone: #{doctor_cellphone}, patient_name: #{patient_name}, patient_cellphone: #{patient_cellphone}"
    end
    visits_15.each do |v|
      doctor_cellphone = '+' + v.oncall_time.doctor.user.country_code+v.oncall_time.doctor.user.cellphone
      doctor_name = v.oncall_time.doctor.user.lastname
      patient_name = v.patient.user.firstname + ' ' + v.patient.user.lastname
      patient_cellphone = '+' + v.patient.user.country_code + v.patient.user.cellphone
      v.send_sms(doctor_cellphone,
                 "Hi Doctor #{doctor_name}, you have a visit at #{v.timerange.begin} with patient #{patient_name}, whose cell number is #{patient_cellphone}.")
      puts "message sent"
      Rails.logger.info "sms requested t-15: doctor_name: #{doctor_name}, doctor_cellphone: #{doctor_cellphone}, patient_name: #{patient_name}, patient_cellphone: #{patient_cellphone}"
    end
    visits_30.each do |v|
      doctor_cellphone = '+' + v.oncall_time.doctor.user.country_code+v.oncall_time.doctor.user.cellphone
      doctor_name = v.oncall_time.doctor.user.lastname
      patient_name = v.patient.user.firstname + ' ' + v.patient.user.lastname
      patient_cellphone = '+' + v.patient.user.country_code + v.patient.user.cellphone
      v.send_sms(doctor_cellphone,
                 "Hi Doctor #{doctor_name}, you have a visit at #{v.timerange.begin} with patient #{patient_name}, whose cell number is #{patient_cellphone}.")
      puts "message sent"
      Rails.logger.info "sms requested t-30: doctor_name: #{doctor_name}, doctor_cellphone: #{doctor_cellphone}, patient_name: #{patient_name}, patient_cellphone: #{patient_cellphone}"
    end
  end
end

# v.timerange = (Time.new + 16.minutes).beginning_of_minute...(Time.now + 22.minutes)
