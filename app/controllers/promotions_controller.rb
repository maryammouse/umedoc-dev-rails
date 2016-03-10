class PromotionsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::OutputSafetyHelper

  def show
    if current_user
      if current_user.doctor
        @promotions = current_user.doctor.promotions.order(:id)
      else
        flash[:warning] = 'Only doctors may access this page! Our apologies.'
        redirect_to('/')
      end
    else
      flash[:warning] = 'Only logged in doctors may access this page! Sorry about that.'
      redirect_to('/')
    end


  end

  def create
    promotion_details = promotion_create_params

    start_datetime = (promotion_details['create_start_date']['year'] + '-' +
      promotion_details['create_start_date']['month'] + '-' +
      promotion_details['create_start_date']['day'] + ' ' +
      '00:00:00').in_time_zone(promotion_details['create']['timezone'])

    end_datetime = (promotion_details['create_end_date']['year'] + '-' +
      promotion_details['create_end_date']['month'] + '-' +
      promotion_details['create_end_date']['day'] + ' ' +
      '24:00:00').in_time_zone(promotion_details['create']['timezone'])


    expiry_datetime = (promotion_details['create_expiry_date']['year'] + '-' +
                       promotion_details['create_expiry_date']['month'] + '-' +
                       promotion_details['create_expiry_date']['day'] + ' ' +
      '24:00:00').in_time_zone(promotion_details['create']['timezone'])

    promotion = Promotion.new

    promotion.applicable_timerange = start_datetime...end_datetime
    promotion.bookable_timerange = start_datetime...expiry_datetime
    promotion.promo_code = (1..6).map { SecureRandom.base64.gsub(/-*\+*\/*\-*\_*\=*/,'').split('').sample }.join
    promotion.timezone = promotion_details['create']['timezone']
    promotion.discount = promotion_details['create']['discount']
    promotion.discount_type = promotion_details['create']['discount_type']
    promotion.max_uses_per_patient = promotion_details['create']['max_uses_per_patient']
    promotion.applicable = 'not_applicable'
    promotion.bookable = 'not_bookable'
    if promotion_details['create']['name'] != ''
      promotion.name = promotion_details['create']['name']
    end
    promotion.doctor_id = current_user.doctor.id



    if promotion.save
      flash[:success] = 'Your promotion has been created!'
    else
      flash[:warning] = "<div align='center'>The promotion could not be created.<br> It contains " + pluralize(promotion.errors.count, "error") + "!<br><br></div>"
      promotion.errors.full_messages.each do |msg|
        flash[:warning] << "<li>" + msg + "</li>"
      end
      flash[:warning] << "<br><div align='center'>Please fix " + "the problem/s" + " and try again.</div>"
    end


    redirect_to('/promotions')
  end

  def switch
    update = promotion_switch_params
    
    update[:promo_applicable].each do |key, value|
      p = Promotion.find(key)
      if value == 'off'
        p.applicable = 'not_applicable'
      end
      if value == 'on'
        p.applicable = 'applicable'
      end


      unless p.save
        flash[:warning] = 'Something has gone wrong! We could not save any or all of your changes.'
      end
    end

    update[:promo_bookable].each do |key, value|
      p = Promotion.find(key)
      if value == 'off'
        p.bookable = 'not_bookable'
      end
      if value == 'on'
        p.bookable = 'bookable'
      end

      unless p.save
        flash[:warning] = 'Something has gone wrong! We could not save any or all of your changes.'
      end
    end

    redirect_to('/promotions')
  end

  def edit
    changes = promotion_edit_params
    promo_code = changes[:edit][:chosen_promo][-6..-1]

    edit_promo = Promotion.find_by(promo_code: promo_code)

    if edit_promo.nil?
      flash[:warning] = 'The promotion could not be edited.'
      redirect_to '/promotions' and return
    end

    start_datetime = (changes['edit_start_date']['year'] + '-' +
      changes['edit_start_date']['month'] + '-' +
      changes['edit_start_date']['day'] + ' ' +
      '00:00:00').in_time_zone(changes['edit']['timezone'])

    end_datetime = (changes['edit_end_date']['year'] + '-' +
      changes['edit_end_date']['month'] + '-' +
      changes['edit_end_date']['day'] + ' ' +
      '24:00:00').in_time_zone(changes['edit']['timezone'])

    expiry_datetime = (changes['edit_expiry_date']['year'] + '-' +
                       changes['edit_expiry_date']['month'] + '-' +
                       changes['edit_expiry_date']['day'] + ' ' +
      '24:00:00').in_time_zone(changes['edit']['timezone'])

    edit_promo.applicable_timerange = start_datetime...end_datetime
    edit_promo.bookable_timerange = start_datetime...expiry_datetime
    edit_promo.timezone = changes['edit']['timezone']
    if changes['edit']['discount'] != ''
      edit_promo.discount = changes['edit']['discount']
    end
    if changes['edit']['max_uses_per_patient'] != ''
      edit_promo.max_uses_per_patient = changes['edit']['max_uses_per_patient']
    end
    if changes['edit']['name'] != ''
      edit_promo.name = changes['edit']['name']
    end

    if edit_promo.save
      flash[:success] = 'Your changes have been saved!'
    else
      flash[:warning] = "<div align='center'>The promotion could not
       be edited.<br> It contains " + pluralize(edit_promo.errors.count, "error") + "!<br><br></div>"
      edit_promo.errors.full_messages.each do |msg|
        flash[:warning] << "<li>" + msg + "</li>"
      end
      flash[:warning] << "<br><div align='center'>Please fix " + "the problem/s" + " and try again.</div>"
    end



    redirect_to('/promotions')
  end

  def delete
    promo = promotion_delete_params
    db_promo = Promotion.find_by(promo_code: promo[:promo_code])

    if PatientsPromotion.find_by(promotion_id: db_promo.id).nil?

      if current_user.doctor.promotions.find_by(promo_code: promo[:promo_code]).destroy
        flash[:success] = 'Your promotion has been successfully deleted!'
      else
        flash[:warning] = "It looks like we couldn't delete the promotion. Sorry about that!"
      end
    else
      flash[:warning] = "This promotion is currently in use! If you wish to disable all coupons
      associated with it and also prevent patients from redeeming the code, set the Code Status and
      Coupon Status to OFF. However, we do not recommend turning off coupons - once a patient has redeemed a code
      and recieved a coupon, they may be particularly upset that it does not work."
    end
    redirect_to('/promotions')
  end

  def select
    @promo = Promotion.find_by(promo_code: params[:promo_code])
    
    render :json => @promo
  end

  def redeem
    if current_user && current_user.patient
      @redeemed = current_user.patient.patients_promotions
    else
      flash[:warning] = "Sorry, only logged in patients can view this page!"
      redirect_to('/') and return
    end


    if params[:redirect_to] == 'booking'
      session[:redirect_to] = '/booking'
    end

  end

  def apply
    code = promotion_apply_params[:promo_code]
    promo = Promotion.find_by(promo_code: code)
    unless Promotion.currently_applicable?(current_user, code)
      flash[:danger] = 'That code cannot be redeemed! Please try another.'
      redirect_to('/promotions/redeem') and return
    end

    pp = PatientsPromotion.new(promotion_id: promo.id, patient_id: current_user.patient.id, uses_counter: 0)
    if pp.save
      flash[:success] = 'Your code was successfully redeemed!'
    else
      flash[:warning] = 'Something went wrong and we could not redeem your coupon! Please try again.'
    end

    if session[:redirect_to] = '/booking'
      redirect_to('/promotions/redeem?redirect_to=booking')
    else
      redirect_to('/promotions/redeem')
    end
  end

  def booking
    code = promotion_apply_params[:promo_code]
    promo = Promotion.find_by(promo_code: code)
    @oncall_time = OncallTime.find_by(id: session[:pv_id].to_i)

    if Promotion.currently_bookable?(current_user, code, @oncall_time.doctor)
      session[:promo_code] = promo.promo_code
      flash[:success] = 'Your code was successfully applied!'
    else
      flash[:danger] = 'That coupon cannot be used! It has either been used up, expired, or can only
      be used for visits with a certain doctor. Please try another.'
    end
    redirect_to('/booking')
  end

  def free_visit
    @oncall_time = OncallTime.find_by(id: session[:pv_id].to_i)
    promo = Promotion.find_by(promo_code: session[:promo_code])
    unless Promotion.currently_bookable?(current_user, promo.promo_code, @oncall_time.doctor)
      flash[:danger] = 'That code is not valid! Please try another.'
      puts current_user.patient.patients_promotions.find_by(promotion_id: promo.id).nil?.to_s
      redirect_to('/booking') and return
    end

    pp = PatientsPromotion.find_by(patient_id: current_user.patient.id, promotion_id: promo.id)
    pp.uses_counter += 1

    unless pp.save 
      flash[:warning] = 'There was an error processing your promo code, please try again or try another!'
      session[:promo_code] = nil
      redirect_to('/booking') and return
    end

    fee = @oncall_time.fee_rules.where('time :start_time <@ time_of_day_range',
                                                  {start_time: Time.parse(session[:pv_start]).getlocal('-07:00').
                                                      strftime("%H:%M:%S") }).
        find_by(day_of_week: Time.parse(session[:pv_start]).getlocal('-07:00').wday).fee

    if Promotion.free_visit?(promo, fee)
      if session[:redirect_to] == '/booking'
        session[:redirect_from] = nil
        session[:redirect_to] = nil
      end
      if session[:pv_office_id]
        @offline_office = OfficeLocation.find_by(id: session[:pv_office_id])
      end
      @start_time = Time.parse(session[:pv_start])
      @end_time = Time.parse(session[:pv_end])

    unless @offline_office
        session_id = OPENTOK.create_session(:media_route=> :routed).session_id
        new_visit = Visit.new(oncall_time_id: @oncall_time.id,
                     patient_id: current_user.patient.id,
                     timerange: (@start_time)..(@end_time),
                     fee_paid: 0,
                     jurisdiction: 'accepted',
                     session_id: session_id
                    )
      else
        new_visit = Visit.new(oncall_time_id: @oncall_time.id,
                     patient_id: current_user.patient.id,
                     timerange: (@start_time)..(@end_time),
                     fee_paid: 0,
                     jurisdiction: 'accepted'
                    )
      end


      unless new_visit.save
        flash[:warning] = 'Something went wrong while creating your visit!'
        new_visit.errors.messages.each do |n|
          flash[:warning] << n
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
    
      session[:pv_start] = nil
      session[:pv_end] = nil
      session[:pv_id] = nil
      session[:promo_code] = nil


      new_visit.visit_notifications

      if @offline_office
        session[:office_id] = nil
        redirect_to('/visits')
      else
        redirect_to('/office')
      end

    else
      flash[:warning] = 'There was some problem with the promo code. Please try again!'
      redirect_to('/')
    end
  end

  private


    def promotion_create_params
      params.permit( {create_start_date: [:year, :month, :day] },
                    { create_end_date: [:year, :month, :day] },
                    { create_expiry_date: [:year, :month, :day] },
                    { create: [:timezone, :max_uses_per_patient, :discount_type, :discount, :name]})
    end

    def promotion_switch_params
      params.permit.tap do |whitelisted|
        whitelisted[:promo_applicable] = params[:promo_applicable]
        whitelisted[:promo_bookable] = params[:promo_bookable]
      end
    end

    def promotion_delete_params
      params.permit(:promo_code)
    end

    def promotion_edit_params
      params.permit( { edit_start_date: [:year, :month, :day] },
                    { edit_end_date: [:year, :month, :day] },
                    { edit_expiry_date: [:year, :month, :day] },
                    { edit: [:chosen_promo, :timezone, :max_uses_per_patient, :discount, :name]})
    end

    def promotion_apply_params
      params.permit(:promo_code)
    end

end
