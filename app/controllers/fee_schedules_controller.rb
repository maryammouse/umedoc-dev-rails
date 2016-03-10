class FeeSchedulesController < ApplicationController
  def create
    fs = FeeSchedule.new(doctor_id: current_user.doctor.id, name: schedule_create_params[:fee_schedule_name])

    if fs.save
      flash[:success] = 'Your schedule has been created! Time to add the rules.'
    else
      flash[:warning] = "<div align='center'>The schedule could not be saved.<br> It contains " + pluralize(ot.errors.count, "error") + "!<br><br></div>"
      fs.errors.full_messages.each do |msg|
        flash[:warning] << "<li>" + msg + "</li>"
      end
      flash[:warning] << "<br><div align='center'>Please fix " + "the problem/s" + " and try again.</div>"
    end

    redirect_to('/dashboard')
  end

  def select
    fs = FeeSchedule.find_by(id: schedule_select_params[:fee_schedule_select])

    session[:current_schedule] = fs.id

    unless session[:current_schedule].nil?
      flash[:success] = "You have selected " + fs.name + "! You can now edit it by filling in the days."
    else
      flash[:warning] = 'We were unable to select the schedule! We are sorry,
       please try again or report a bug if it continues.'
    end

    redirect_to('/dashboard')
  end

  def fee_rule
    @fee_rule = FeeRule.find_by(id: params[:fee_rule])

    render :json => @fee_rule
  end

  def edit
    @current_schedule = FeeSchedule.find(session[:current_schedule])
    if schedule_edit_params[:submit_type] == 'add'
      @fee_rule = FeeRule.new(fee_schedule_id: session[:current_schedule])
    elsif schedule_edit_params[:submit_type] == 'edit'
      @fee_rule = FeeRule.find_by(id: schedule_edit_params[:id_box])
    end


    if @fee_rule.nil?
      flash[:warning] = 'Sorry, there was a weird error with our code, can you please try again
                          or report it using the blue button on the bottom right?'
      redirect_to('/dashboard') and return
    end




    @fee_rule.time_of_day_range =    "[" + schedule_edit_params[:start_time] + "," + schedule_edit_params[:end_time] + ")"
    # @fee_rule.time_of_day_range = "timerange::" +   "[" + schedule_edit_params[:start_time] + "," + schedule_edit_params[:end_time] + ")"

    if @fee_rule.time_of_day_range.begin == nil or
        @fee_rule.time_of_day_range.end == nil
    end



    @fee_rule.fee = '-100'
    @fee_rule.online_visit_fee = schedule_edit_params[:online_fee]
    @fee_rule.office_visit_fee = schedule_edit_params[:office_fee]
    if @fee_rule.day_of_week.nil?
      @fee_rule.day_of_week = schedule_edit_params[:day_keeper]
    end

    if schedule_edit_params[:online_visit_allowed] == 'on'
      @fee_rule.online_visit_allowed = 'allowed'
    elsif schedule_edit_params[:online_visit_allowed] == 'off'
      @fee_rule.online_visit_allowed = 'not_allowed'
    end

    if schedule_edit_params[:office_visit_allowed] == 'on'
      @fee_rule.office_visit_allowed = 'allowed'
    elsif schedule_edit_params[:office_visit_allowed] == 'off'
      @fee_rule.office_visit_allowed = 'not_allowed'
    end


    if @fee_rule.save

      respond_to do |format|
        format.js { render action: "edit" }
        format.json { render json: @fee_rule }
      end

    else

      flash[:warning] = "<div align='center'>The time block could not be saved.<br> It contains "
      + pluralize(ot.errors.count, "error") + "!<br><br></div>"
      @fee_rule.errors.full_messages.each do |msg|
        flash[:warning] << "<li>" + msg + "</li>"
      end
      flash[:warning] << "<br><div align='center'>Please fix " + "the problem/s" + " and try again.</div>"

      respond_to do |format|
        format.html { render action: "new" }
        format.json { render json: @fee_rule.errors, status: :unprocessable_entity }
      end
    end
  end

  def schedule_create_params
    params.permit(:fee_schedule_name)
  end

  def schedule_select_params
    params.permit(:fee_schedule_select)
  end

  def schedule_edit_params
    params.permit(:submit_type, :id_box, :day_keeper, :start_time, :end_time, :online_fee,
                  :office_fee, :online_visit_allowed, :office_visit_allowed)
  end
end
