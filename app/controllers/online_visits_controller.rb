class OnlineVisitsController < ApplicationController

  def show
    unless logged_in?
      return
    end


    doctor = Doctor.find_by(user_id: current_user.id)
    if doctor.nil?
      visits = Visit.joins(:online_locations).where(patient_id: current_user.patient.id)
    else
      visits = doctor.visits.joins(:online_locations)
    end

    @upcoming_visit = visits.where("lower(visits.timerange) > :current_time",
                                    current_time: Time.now).order(timerange: :asc).first
    @last_visit = visits.where("upper(visits.timerange) < :current_time",
                                 current_time: Time.now).order(timerange: :desc).first
    @current_visit = visits.where("lower(visits.timerange) < :current_time",
                                  current_time: Time.now)
    @current_visit = @current_visit.where("upper(visits.timerange) > :current_time",
                                         current_time: Time.now).first
    if @last_visit
      @old_messages = ChatEntry.where(session_id: @last_visit.session_id)
      @old_messages.destroy_all
    end

    if @current_visit and @current_visit.authenticated == '0' and current_user.doctor #  session[:redirect_from] != '/verify'
      session[:current_visit_id] = @current_visit.id
      session[:redirect_to] = '/office'
      response_sms = Authy::API.request_sms(:id => current_user.authy_id)
      redirect_to('/verify') and return
    end

    unless @current_visit.nil?

      @token = OPENTOK.generate_token(@current_visit.session_id, role: :moderator,
                                      expire_time: @current_visit.timerange.end)
      session[:visit_session_id] = @current_visit.session_id

      @messages = ChatEntry.where(session_id: @current_visit.session_id).order(created_at: :asc)
    end
  end
end
