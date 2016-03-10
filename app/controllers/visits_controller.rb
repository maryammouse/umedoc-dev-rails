class VisitsController < ApplicationController

  def show
    unless logged_in?
      redirect_to('/') and return
    end

    doctor = Doctor.find_by(user_id: current_user.id)
    if doctor.nil?
      visits = Visit.where(patient_id: current_user.patient.id)
    else
      visits = doctor.visits
    end

    @future_visits = visits.where("lower(visits.timerange) > :current_time",
                                current_time: Time.now).order(timerange: :asc)

    @upcoming_visit = @future_visits.first

    @past_visits = visits.where("upper(visits.timerange) < :current_time",
                                 current_time: Time.now).order(timerange: :desc)
    
    @last_visit = @past_visits.first
    
  end

end
