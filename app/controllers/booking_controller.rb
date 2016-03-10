class BookingController < ApplicationController
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::DateHelper
  skip_before_action :verify_authenticity_token

  def new
    Stripe.api_key = ENV['STRIPE_SK']
    if logged_in?
      if current_user.doctor
        flash[:warning] = "Sorry, doctors can't book visits! You need to make a patient account by logging out, then clicking on 'Sign Up' in the top right corner."
        redirect_to('/')
      end


    else
      session[:redirect_to] = '/booking'
      @offline_office = OfficeLocation.find_by(id: session[:pv_office_id])
    end

    @oncall_time = OncallTime.find_by(id: session[:pv_id].to_i)
    if @oncall_time.nil? or (@oncall_time.bookable = false)
      flash[:warning] = "We're so sorry, that visit is no longer available. Please book another!"
      redirect_to('/') and return
    else
    end

    if session[:pv_office_id]
      @fee = @oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                                    {start_time: DateTime.parse(session[:pv_start]).in_time_zone('US/Pacific').
                                                        strftime("%H:%M:%S") }).
          find_by(day_of_week: DateTime.parse(session[:pv_start]).in_time_zone('US/Pacific').wday).office_visit_fee
    else
      @fee = @oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                         {start_time: DateTime.parse(session[:pv_start]).in_time_zone('US/Pacific').
                                             strftime("%H:%M:%S") }).
          find_by(day_of_week: DateTime.parse(session[:pv_start]).in_time_zone('US/Pacific').wday).online_visit_fee
    end

    if session[:promo_code]
      if Promotion.currently_bookable?(current_user, session[:promo_code], @oncall_time.doctor)
          @promo = Promotion.find_by(promo_code: session[:promo_code])
          if Promotion.free_visit?(@promo, @fee)
            @free_visit = 'free!'
          end
      else
          flash.now[:warning] = "We're sorry, the code that was applied is invalid for this visit and has been removed."
          session[:promo_code] = nil
      end
    else
        session[:promo_code] = nil
    end

    if logged_in?
      @offline_office = OfficeLocation.find_by(id: session[:pv_office_id])
      @customer = StripeCustomer.find_by(user_id: current_user.id)
      @redeemed = current_user.patient.patients_promotions.joins(:promotion).
          where(promotions:
                    { doctor_id: @oncall_time.doctor.id} )
      if @customer
        @stripe_customer = Stripe::Customer.retrieve(@customer.customer_id)
        if @stripe_customer.default_source
          @card = @stripe_customer.sources.retrieve(@stripe_customer.default_source)
        end
      end
    end

  end

  def create
    if session[:redirect_to] == '/booking'
      session[:redirect_from] = nil
      session[:redirect_to] = nil
    end
    if session[:pv_office_id]
      @offline_office = OfficeLocation.find_by(id: session[:pv_office_id])
    end
    @oncall_time = OncallTime.find_by(id: session[:pv_id])
    @start_time = Time.parse(session[:pv_start])
    @end_time = Time.parse(session[:pv_end])
    @access_token = @oncall_time.doctor.user.stripe_seller.access_token # doctor access_token
    Stripe.api_key = ENV['STRIPE_SK']

    if session[:promo_code]
      if Promotion.currently_bookable?(current_user, session[:promo_code], @oncall_time.doctor)
        @promo = Promotion.find_by(promo_code: session[:promo_code])

      else
        flash[:warning] = "We're sorry, the code that was applied to this visit was invalid and has been removed."
        session[:promo_code] = nil
        redirect_to('/booking') and return
      end
    end


    # Get the credit card details submitted by the form
    token_id = params[:stripeToken]

    # Create a Customer FOR THE APPLICATION
    if current_user.stripe_customer.nil?
      begin
      @stripe_customer = Stripe::Customer.create(
        {
        :source => token_id,
        :description => current_user.username
        }
      )


      StripeCustomer.create(user_id: current_user.id, customer_id: @stripe_customer.id)

      rescue => e
        flash[:warning] = e
        redirect_to '/booking'
      end
    end


      #@fee_amount = (@free_time.oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
      #                                                      {start_time: @start_time.in_time_zone("Pacific Time (US & Canada)")}).find_by(
      #                                                      day_of_week: @start_time.in_time_zone("Pacific Time (US & Canada)").wday).fee * 100).round

    if session[:pv_office_id]
      @fee_amount = (@oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                          {start_time: Time.parse(session[:pv_start]).getlocal('-07:00').
                                              strftime("%H:%M:%S") }).
          find_by(day_of_week: Time.parse(session[:pv_start]).getlocal('-07:00').wday).office_visit_fee * 100).round
    else
      @fee_amount = (@oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                          {start_time: Time.parse(session[:pv_start]).getlocal('-07:00').
                                              strftime("%H:%M:%S") }).
          find_by(day_of_week: Time.parse(session[:pv_start]).getlocal('-07:00').wday).online_visit_fee * 100).round
    end

      if @promo
        @fee_amount  = (@fee_amount.to_f - (@fee_amount.to_f * (@promo.discount.to_f / 100.0))).to_i

        pp = current_user.patient.patients_promotions.find_by(promotion_id: @promo.id)
        pp.uses_counter += 1

        unless pp.save
          flash[:danger] = 'There was an error with your coupon - please try again or contact us
                            if problems continue!'

          redirect_to('/booking') and return
        end

        session[:promo_code] = nil
      end

      unless @offline_office
        session_id = OPENTOK.create_session(:media_route=> :routed).session_id
        new_visit = Visit.new(oncall_time_id: @oncall_time.id,
                     patient_id: current_user.patient.id,
                     timerange: (@start_time)..(@end_time),
                     duration: distance_of_time_in_words(@end_time - @start_time),
                     fee_paid: @fee_amount,
                     jurisdiction: 'accepted',
                     session_id: session_id
                    )
      else
        new_visit = Visit.new(oncall_time_id: @oncall_time.id,
                     patient_id: current_user.patient.id,
                     timerange: (@start_time)..(@end_time),
                     duration: distance_of_time_in_words(@end_time - @start_time),
                     fee_paid: @fee_amount,
                     jurisdiction: 'accepted'
                    )
      end

      begin
        new_visit.save
      rescue => e
        new_visit.errors.full_messages.each do |n|
        flash[:danger] = "<li>" + n + "</li>"
        end
        redirect_to('/booking') and return
      end

      if new_visit.errors.count > 0
        flash[:warning] = "<div align='center'>The visit could not
       be created.<br> It contains " + pluralize(new_visit.errors.count, "error") + "!<br><br></div>"
        new_visit.errors.full_messages.each do |msg|
          flash[:warning] << "<li>" + msg + "</li>"
        end
        redirect_to('/booking') and return
      end




      if @offline_office
        office_loc = VisitsOfficeLocation.new(visit_id: new_visit.id, office_location_id: @offline_office.id )
        unless office_loc.save
          puts " PROBLEM WITH SAVING LOCATION:"
          office_loc.errors.messages.each do |n|
            puts n
          end
        end
      else
        @oncall_time.online_locations.each do |n|
          online_loc = VisitsOnlineLocation.create(visit_id: new_visit.id, online_location_id: n.id )
        end
      end


    session[:promo_code] = nil


    # add code for visit_notification job
    logger.debug "new_visit.inspect has the value:"
    logger.debug new_visit.inspect

    logger.debug "about to call new_visit.visit_notifications"
    new_visit.visit_notifications
    logger.debug "should have called new_visit.visit_notifications"


    if @offline_office
      session[:office_id] = nil
      redirect_to('/visits') and return
    else
      redirect_to('/office') and return
    end

    redirect_to('/visits') and return
  end
end
