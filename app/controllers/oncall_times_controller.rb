class OncallTimesController < ApplicationController
  include ActionView::Helpers::TextHelper
  def index
    unless logged_in? && current_user.doctor && (current_user.doctor.verification_status == 'verified')
      flash[:warning] = "Only logged in, verified doctors can visit this page!"
      redirect_to('/') and return
    end

    @future_oncall_times = OncallTime.where(doctor_id: current_user.doctor.id).
        where("upper(oncall_times.timerange) > :current_time",
            current_time: Time.now).
        order(id: :asc)

    @past_oncall_times = OncallTime.where(doctor_id: current_user.doctor.id).
        where("upper(oncall_times.timerange) < :current_time",
              current_time: Time.now).
        order(id: :desc).page(params[:page]).per(5)

    @fee_schedules = FeeSchedule.where(doctor_id: current_user.doctor.id).order(id: :asc)
    unless session[:current_schedule].nil?
      @current_schedule = FeeSchedule.find(session[:current_schedule])
    end

  end

  def create

    ot_params =  oncall_time_params


    Time.zone = ot_params['create']['timezone']
    Chronic.time_class = Time.zone
    ot = OncallTime.new(doctor_id: current_user.doctor.id,
                        timerange: Chronic.parse(ot_params["start_datetime"])...Chronic.parse(ot_params["end_datetime"]),
                        fee_schedule_id: ot_params["fee_schedules"]
    )



    if ot.save
      if ot_params[:online] == 'on'
      end
      otol_errors = :no_errors_found #initialization
      if ot_params[:online] == 'on'
        online_locations = []
        ot.doctor.state_medical_boards.each do |smb|
          online_locations << OnlineLocation.find_by(state: smb.state )
        end
        if online_locations.present?
          online_locations.each do |ol|
            otol = OncallTimesOnlineLocation.
              new(oncall_time_id: ot.id,
                     online_location_id: ol.id )
            otol.save
            if otol.errors.present?
              otol_errors = :errors_found #set flag if errors found
              flash[:warning] = 'We could not set the Online Office as a valid location, please try again!'
              redirect_to('/dashboard') and return
            end
          end
        else
          flash[:warning] = 'We could not set the Online Office as a valid location, please try again!'
          redirect_to('/dashboard') and return
        end
      end
      unless ot_params[:office_locations] == 'none'
        otof = OncallTimesOfficeLocation.new(oncall_time_id: ot.id, office_location_id: ot_params[:office_locations])
        otof.save
        if otof.errors.present?  or  otol_errors == :errors_found
          ot.destroy
          flash[:warning] = 'We could not save your availability locations! Please try again.<p>'
          otof.errors.full_messages.each do |msg|
            flash[:warning] << '<li>' + msg + '</li>'
          end
        else
          flash[:success] = 'You have successfully submitted your availability!'
        end
      end

      else
        flash[:warning] = "<div align='center'>The availability time range could not be saved.<br> It contains " + pluralize(ot.errors.count, "error") + "!<br><br></div>"
        ot.errors.full_messages.each do |msg|
          flash[:warning] << "<li>" + msg + "</li>"
        end
        flash[:warning] << "<br><div align='center'>Please fix " + "the problem/s" + " and try again.</div>"
    end
    redirect_to('/dashboard')
  end

  def switch
    ots = oncall_time_switch_params

    ots[:oncall_time].each do |key, value|
      ot = OncallTime.find(key)
      if value == 'off'
        ot.bookable = false
      end
      if value == 'on'
        ot.bookable = true
      end

      unless ot.save(validate: false)
        flash[:warning] = 'Something has gone wrong! We could not save any or all of your changes.<br>'
        flash[:warning] << ot.id.to_s + ' errors: '
        ot.errors.full_messages.each do |msg|
          flash[:warning] << '<li>' + msg + '</li>'
        end
      end
    end

    redirect_to('/dashboard')

  end

  private

  def oncall_time_params
    params.permit(:start_datetime, :end_datetime, :online, :office_locations, :fee_schedules,
    { create: [:timezone]})
  end

  def oncall_time_switch_params
    params.permit.tap do |whitelisted|
      whitelisted[:oncall_time] = params[:oncall_time]
      end
  end

end
